package RT::Ticket;

use strict;
use warnings;
use Encode qw/decode_utf8/;

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
