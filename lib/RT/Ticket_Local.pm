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

  ######################################
  # Due Date
  ######################################
  my $DueConfig = RT->Config->Get('SearchResult_HighlightOnDueDate');

  # ascending order. 3 wins over 8 for due dates. Nested hash sorting needed.
  for my $c ( sort {$a->{conditions}{due} <=> $b->{conditions}{due}} @{$DueConfig}) {
    next if (!defined($c->{'conditions'}));

    next if ($mode eq 'rowclass' && !defined($c->{'color'}));
    next if ($mode eq 'icon' && !defined($c->{'icon'}));

    my $conditions = $c->{'conditions'};
    my $icon = $c->{'icon'};
    my $color = $c->{'color'};
    my $tooltip = $c->{'tooltip'};

    # RT stores dates in Unix zero, if not set by the user
    if ($ticket->DueObj->Unix != 0) {
      my $now = new RT::Date($RT::SystemUser);
      $now->SetToNow();

      my $diff = $ticket->DueObj->Diff($now);

      for my $key (keys %{$conditions}) {
        next if $key ne 'due';

        my $value = %{$conditions}{$key};

        if ($diff < 60 * 60 * 24 * $value) {
          RT::Logger->debug("Ticket #". $ticket->id ." will be due in < $value days, diff is ". ($diff / (60*60*24))  ." days. Marking search result.");
          return getHighlightValue($ticket, $mode, $color, $icon, $tooltip);
        }
      }
    }

  }

  ######################################
  # Ticket Last Updated By Condition
  ######################################
  my $LastUpdatedByConfig = RT->Config->Get('SearchResult_HighlightOnLastUpdatedByCondition');

  my $ownerObj = $ticket->OwnerObj;
  my $owner = $ownerObj->id;
  my $ownerGroups = $ownerObj->OwnGroups;

  my $lastUpdatedByObj = $ticket->LastUpdatedByObj;
  my $lastUpdatedBy = $lastUpdatedByObj->id;
  my $lastUpdatedByGroups = $lastUpdatedByObj->OwnGroups;

  for my $c (@{$LastUpdatedByConfig}) {
    next if (!defined($c->{'conditions'}));

    next if ($mode eq 'rowclass' && !defined($c->{'color'}));
    next if ($mode eq 'icon' && !defined($c->{'icon'}));

    my $conditions = $c->{'conditions'};
    my $icon = $c->{'icon'};
    my $color = $c->{'color'};
    my $tooltip = $c->{'tooltip'};

    if (defined($conditions->{'owner'})) {
      # don't care about the value, just compare owner with last update by
      if ("$owner" ne "$lastUpdatedBy") {
        return getHighlightValue($ticket, $mode, $color, $icon, $tooltip);
      }
    }

    if (defined($conditions->{'groups'})) {
      # check whether last reply did not happen from outside group members
      my $highlight = 1;

      for my $groupName (@{ $conditions->{'groups'} }) {
        my $group = RT::Group->new();
        $group->LoadUserDefinedGroup($groupName);

        if ($group->HasMemberRecursively($lastUpdatedBy)) {
          $highlight = 0;
          last;
        }
      }

      if ($highlight == 1) {
        return getHighlightValue($ticket, $mode, $color, $icon, $tooltip);
      }
    }
  }

  ######################################
  # CF conditions
  ######################################
  my $CFConfig = RT->Config->Get('SearchResult_HighlightOnCFCondition');

  for my $c (@{$CFConfig}) {
    next if (!defined($c->{'conditions'}));

    next if ($mode eq 'rowclass' && !defined($c->{'color'}));
    next if ($mode eq 'icon' && !defined($c->{'icon'}));

    my $conditions = $c->{'conditions'};
    my $icon = $c->{'icon'};
    my $color = $c->{'color'};
    my $tooltip = $c->{'tooltip'};

    for my $key (keys %{$conditions}) {
      my $value = %{$conditions}{$key};

      my $cfValue = $ticket->FirstCustomFieldValue($key);

      # CF equal match
      if (defined($cfValue) && "$cfValue" =~ /$value/) {
        return getHighlightValue($ticket, $mode, $color, $icon, $tooltip);
      }
    }
  }

}

## Highlight value helper
sub getHighlightValue {
  my $ticket = shift;
  my $mode = shift;
  my $color = shift;
  my $icon = shift;
  my $tooltip = shift;

  if ($mode eq 'rowclass') {
    return "row-bg-color-".$color;
  } elsif ($mode eq 'icon') {
    # The backslash is important, RT does render this HTML snippet later.
    return \"<span class=\"fa $icon\" title=\"$tooltip\"></span>";
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
