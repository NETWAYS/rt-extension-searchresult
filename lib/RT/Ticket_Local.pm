package RT::Ticket;

use strict;
use warnings;
use Encode qw/decode_utf8/;

# Highlight rows on Conditions
sub getHighlight {
  my $ticket = shift;
  my $mode = shift;

  if ($mode ne 'icon' && $mode ne 'rowclass') {
    RT->Logger->crit("Programming error: Wrong mode $mode passed.");
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

    # Diff() compares against "now" and returns undef when no due date is set,
    # so there is no need to build a separate RT::Date for the current time.
    my $diff = $ticket->DueObj->Diff;
    if (defined $diff) {

      for my $key (keys %{$conditions}) {
        next if $key ne 'due';

        my $value = $conditions->{$key};

        if ($diff < 60 * 60 * 24 * $value) {
          RT->Logger->debug("Ticket #". $ticket->id ." will be due in < $value days, diff is ". ($diff / (60*60*24))  ." days. Marking search result.");
          return getHighlightValue($ticket, $mode, $color, $icon, $tooltip);
        }
      }
    }

  }

  ######################################
  # Ticket Last Updated By Condition
  ######################################
  my $LastUpdatedByConfig = RT->Config->Get('SearchResult_HighlightOnLastUpdatedByCondition');

  # Owner/last-updater are DB lookups; only resolve them when this section is
  # actually configured (otherwise the loop below never runs anyway).
  my ($owner, $lastUpdatedBy);
  if ($LastUpdatedByConfig && @{$LastUpdatedByConfig}) {
    $owner        = $ticket->OwnerObj->id;
    $lastUpdatedBy = $ticket->LastUpdatedByObj->id;
  }

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
        my $group = RT::Group->new(RT->SystemUser);
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
      my $value = $conditions->{$key};

      my $cfValue = $ticket->FirstCustomFieldValue($key);

      # CF regex match: the configured value is used as a regular expression
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
    # The backslash is important: a scalar ref tells RT to render this HTML
    # snippet as-is instead of escaping it.
    return \"<i class=\"bi bi-$icon\" title=\"$tooltip\"></i>";
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
