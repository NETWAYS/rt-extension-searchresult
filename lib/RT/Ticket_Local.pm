package RT::Ticket;

use strict;
use warnings;
use Encode qw/decode_utf8/;

# Highlight rows on Conditions
sub getFAIconCode {
  my $ticket = shift;

  # CF conditions
  my $CFConfig = RT->Config->Get('SearchResult_HighlightOnCFCondition');

  return undef if !defined($CFConfig);

  my $highlight = 0;

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

  # Ticket Last Reply Condition
  my $LastReplyConfig = RT->Config->Get('SearchResult_HighlightOnLastReplyCondition');

  return undef if !defined($LastReplyConfig);

  for my $lrc (@{$LastReplyConfig}) {
    my $LRConditions = $lrc->{'conditions'};
    my $LRFAIcon = $lrc->{'icon'};

    if (defined($LRConditions->{'owner'})) {
      # don't care about the value, just compare owner with last reply

      my $owner = $ticket->OwnerAsString;
      my $lastUpdatedByObj = $ticket->LastUpdatedByObj;
      my $lastUpdatedBy = $lastUpdatedByObj->Name;

      if ("$owner" ne "$lastUpdatedBy") {
        # The backslash is important, RT does render this HTML snippet later.
        return \"<span class=\"fa $LRFAIcon\"></span>";
      }

#      my $transactions = $ticket->Transactions;
#
#      my $i = 0;
#      while (my $t = $transactions->Next) {
#         last if ($i > 1); # only one transaction
#
#         use Data::Dumper;
#         RT::Logger->warn("Transaction creator: ".Dumper($t->CreatorObj));
#
#    #    if ($t->Type eq 'Correspond') { #TODO: Filter on transaction types?
#           if ($t->CreatorObj->RealName ne $owner) {
#             # The backslash is important, RT does render this HTML snippet later.
#             return \"<span class=\"fa $LRFAIcon\"></span>";
#           }
#    #    }
#
#        $i = $i + 1;
#      }
    }
    if (defined($LRConditions->{'group'})) {
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
