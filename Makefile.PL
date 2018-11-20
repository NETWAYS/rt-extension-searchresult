use inc::Module::Install;

RTx     'RT-Extension-SearchResult';
license 'gpl_2';
repository 'https://github.com/NETWAYS/rt-extension-searchresult';
readme_from 'lib/RT/Extension/SearchResult.pm';

requires_rt '4.4.3';

sign;
WriteAll;
