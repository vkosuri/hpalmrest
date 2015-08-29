# hpalmrest
All hp alm rest apis

A working example

``` tcl 
%  lappend auto_path [file join [pwd]]
%  lappend auto_path [file join [pwd] hpalmrest]
%  lappend auto_path [file join [pwd] hpalmrest utils]
% package require hpalmrest
% package require hpalmutils
% ::hpalm::login http://my-almhp:8080 testuser testuser domain project
<login>
<cookie>LWSSO_COOKIE_KEY=JygOQ4LHDjNZbcyWFauZ6ziqwvZRZHcJEOJ7rgn1Akz0UZKYW87TuNy
cUQORuJaNxT0G7O5qHmWzuiaNBB8Hm1aqdrXCBA_Jbna2ScTc7rJT0v7GPhGwap0UmIjwDA434k9WLBc
_oeEMYCKlfc_hd2PMSgJdOUlRkzKypwcSQRAZJ_18WStwZqlJN7fhSnXoI5VdoOmMt8GU8hAV40vmUw.
.;Path=/;QCSession=MTM0MTMzNjtmMnh0OUUyTlU0RHNYLWNQRTV6eGhnKio7UkVTVCBjbGllbnQ7I
Dsg;Path=/</cookie>
<status>200</status>
</login>
%
```
