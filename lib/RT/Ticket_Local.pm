package RT::Ticket;

use strict;
use warnings;
use Encode qw/decode_utf8/;

# Highlight rows on Conditions
sub getHighlight {
  my $ticket = shift;
  my $mode = shift;

  if ($mode ne 'icon' && $mode ne 'rowclass') {
    RT::Logger->crit("Programming error: Wrong mode $mode passed.");
    return;
  }

  # CF conditions
  my $CFConfig = RT->Config->Get('SearchResult_HighlightOnCFCondition');

  for my $c (@{$CFConfig}) {
    my $CFConditions = $c->{'conditions'};
    my $CFFAIcon = $c->{'icon'};
    my $CFBGColor = $c->{'color'};

    for my $key (keys %{$CFConditions}) {
      my $value = %{$CFConditions}{$key};

      my $cfValue = $ticket->FirstCustomFieldValue($key);

      # CF equal match
      if (defined($cfValue) && "$cfValue" =~ /$value/) {
        if ($mode eq 'rowclass') {
          return "row-bg-color-".$CFBGColor;
        } elsif ($mode eq 'icon') {
          # The backslash is important, RT does render this HTML snippet later.
          return \"<span class=\"fa $CFFAIcon\"></span>";
        }
      }
    }
  }

  # Ticket Last Updated By Condition
  my $LastUpdatedByConfig = RT->Config->Get('SearchResult_HighlightOnLastUpdatedByCondition');

  my $ownerObj = $ticket->OwnerObj;
  my $owner = $ownerObj->id;
  my $ownerGroups = $ownerObj->OwnGroups;

  my $lastUpdatedByObj = $ticket->LastUpdatedByObj;
  my $lastUpdatedBy = $lastUpdatedByObj->id;
  my $lastUpdatedByGroups = $lastUpdatedByObj->OwnGroups;

  for my $lubc (@{$LastUpdatedByConfig}) {
    my $LUBConditions = $lubc->{'conditions'};
    my $LUBFAIcon = $lubc->{'icon'};
    my $LUBBGColor = $lubc->{'color'};

    if (defined($LUBConditions->{'owner'})) {
      # don't care about the value, just compare owner with last update by
      #RT::Logger->debug("Owner: $owner Last updated by $lastUpdatedBy");

      if ("$owner" ne "$lastUpdatedBy") {
        if ($mode eq 'rowclass') {
          return "row-bg-color-".$LUBBGColor;
        } elsif ($mode eq 'icon') {
          # The backslash is important, RT does render this HTML snippet later.
          return \"<span class=\"fa $LUBFAIcon\"></span>";
        }
      }
    }
    if (defined($LUBConditions->{'groups'})) {
      # check whether last reply did not happen from outside group members
      my $highlight = 1;

      for my $groupName (@{ $LUBConditions->{'groups'} }) {
        my $group = RT::Group->new();
        $group->LoadUserDefinedGroup($groupName);

        if ($group->HasMemberRecursively($lastUpdatedBy)) {
          $highlight = 0;
          last;
        }
      }

      if ($highlight == 1) {
        if ($mode eq 'rowclass') {
          return "row-bg-color-".$LUBBGColor;
        } elsif ($mode eq 'icon') {
          # The backslash is important, RT does render this HTML snippet later.
          return \"<span class=\"fa $LUBFAIcon\"></span>";
        }
      }
    }
  }
}

## Ticket Preview
sub Preview {
  my $self = shift;

  my $content;
  my $attachments = $self->Attachments();

  return '' if (!defined($attachments));

  while (my $a = $attachments->Next) {
    if ($a->ContentType eq 'text/plain') {
      $content = $a->Content;
      last;
    }
  }

  RT::Logger->debug("Fetched first attachment content: $content");

  my $line_limit = RT->Config->Get('SearchResult_PreviewEnabled')->{'lines'};
  my @lines = ();

  for my $line (split /\n/, $content) {
    next if $line =~ m/^\s*$/xms; # ignore empty lines
    push @lines, $line;

    last if scalar @lines >= $line_limit;
  }

  return decode_utf8(join(' ', @lines));
}

1;
