package RT::Ticket;

use strict;
use warnings;
use Encode qw/decode_utf8/;

# Highlight rows on Conditions
sub getFAIconCode {
  my $ticket = shift;

  # CF conditions
  my $CFConfig = RT->Config->Get('SearchResult_HighlightOnCFCondition');

  for my $c (@{$CFConfig}) {
    my $CFConditions = $c->{'conditions'};
    my $CFFAIcon = $c->{'icon'};

    for my $key (keys %{$CFConditions}) {
      my $value = %{$CFConditions}{$key};

      my $cfValue = $ticket->FirstCustomFieldValue($key);

      if ("$cfValue" eq "$value") {
        # The backslash is important, RT does render this HTML snippet later.
        return \"<span class=\"fa $CFFAIcon\"></span>";
      }
    }
  }

  # Ticket Last Updated By Condition
  my $LastUpdatedByConfig = RT->Config->Get('SearchResult_HighlightOnLastUpdatedByCondition');

  for my $lubc (@{$LastUpdatedByConfig}) {
    my $LUBConditions = $lubc->{'conditions'};
    my $LUBFAIcon = $lubc->{'icon'};

    if (defined($LUBConditions->{'owner'})) {
      # don't care about the value, just compare owner with last update by
      my $ownerObj = $ticket->OwnerObj;
      my $owner = $ownerObj->Name;
      my $lastUpdatedByObj = $ticket->LastUpdatedByObj;
      my $lastUpdatedBy = $lastUpdatedByObj->Name;

      #RT::Logger->debug("Owner: $owner Last updated by $lastUpdatedBy");

      if ("$owner" ne "$lastUpdatedBy") {
        # The backslash is important, RT does render this HTML snippet later.
        return \"<span class=\"fa $LUBFAIcon\"></span>";
      }
    }
    if (defined($LUBConditions->{'group'})) {
      # check whether last reply did not happen from outside group members
    }
  }
}

sub getRowBGColorClass {
  my $ticket = shift;

  my $CFConfig = RT->Config->Get('SearchResult_HighlightOnCFCondition');

  return undef if !defined($CFConfig);

  for my $c (@{$CFConfig}) {
    my $CFConditions = $c->{'conditions'};
    my $CFBGColor = $c->{'color'};

    for my $key (keys %{$CFConditions}) {
      my $value = %{$CFConditions}{$key};

      my $cfValue = $ticket->FirstCustomFieldValue($key);

      if ("$cfValue" eq "$value") {
        return "row-bg-color-".$CFBGColor;
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
