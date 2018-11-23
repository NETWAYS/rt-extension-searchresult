package RT::Extension::SearchResult;

use 5.10.1;
use strict;
use version;
use RT;

our $VERSION='0.9.0';

RT->AddJavaScript('fontawesome-svg/js/fontawesome-all.min.js');
RT->AddStyleSheets('searchresult.css');

=pod

=head1 NAME

RT::Extension::SearchResult

=head1 DESCRIPTION

=head1 RT VERSION

Works with RT 4.4.3

=head1 REQUIREMENTS

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit your F</opt/rt4/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::SearchResult');

=item Clear your mason cache

    rm -rf /opt/rt4/var/mason_data/obj

=item Restart your webserver

=back

=head1 CONFIGURATION

Check the online documentation at
https://github.com/NETWAYS/rt-extension-searchresult

=over

=item C<# Enables everything provided by RT::Extension::SearchResult>

=back

=head1 AUTHOR

NETWAYS GmbH <support@netways.de>

=head1 BUGS

All bugs should be reported on L<GitHub|https://github.com/NETWAYS/rt-extension-ticketactions>.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2018 by NETWAYS GmbH

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut

1;
