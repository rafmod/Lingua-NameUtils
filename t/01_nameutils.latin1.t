#!/usr/bin/env perl

# Lingua::NameUtils - Identify given/family names and capitalize correctly
#
# Copyright (C) 2023 raf <raf@raf.org>
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
# 20230709 raf <raf@raf.org>

use 5.014;
use strict;
use warnings;
use charnames ':full'; # For perl v5.14
use open qw(:std :encoding(UTF-8));

# Test Lingua::NameUtils

use Lingua::NameUtils ':all';
use List::Util 'sum';

use Test::More;
use Test::Deep;
use Test::Warnings;
my $nowarnings = 1;

# Test cases are either:
#
# - "strings" containing an unambiguous full name:
#   tested as supplied, and as ambiguous, and both uppercased,
#   and both lowercased, with namecase, gnamecase, fnamecase,
#   namesplit, and nameparts.
#
# - [arrayref] containing two items: an unambiguous full name,
#   followed by the expected incorrect namesplit result.
#   The same tests as above for "strings" are performed.
#   These demonstrate known limitations.
#
# - {hashref} containing a "name" string, a "case" string showing
#   the expected possibly incorrect namecase result, and a "split"
#   string showing the expected possibly incorrect namesplit result.
#   These demonstrate known limitations.
#
# - "strings" containing a single (given or family) name:
#   tested as supplied, and as uppercased, and as lowercased, with
#   namecase, gnamecase, fnamecase, namesplit, and nameparts.

my @test_cases =
(
	undef,
	"",

	"Smith, John Peter",
	"of Lethington, William Maitland", # Split wrong by default (would need an exception)

	"McAdam, Shaun",
	"MacDonald, Fergus",
	"Macquarie, Lachlan",
	"FitzPatrick, James",
	"O'Brian, Patrick",
	"St Clair, Kelly",
	"St. Clair, Kelly",
	"Ste Clair, Kelly",
	"Ste. Clair, Kelly",

	"Le Page, David",
	"La Tour, Pierre",
	"Li Donni, Rochelle",
	"Lo Giudice, Giovanni",
	"d'Iapico-Bien, Estella",
	"dall'Agnese, Bruno",
	"dell'Agnese, Bruno",
	"de\N{RIGHT SINGLE QUOTATION MARK} Medici, Lorenzo",
	"de' Medici, Lorenzo",
	"de Groot, John",
	"de la Pierre, Pierre",
	"del Mar, Maria",
	"dela Mar, Maria",
	"dels �ngels, Maria",
	"della Vella, Giaccomo",
	"delle Velle, Giovanni",
	"dal Santos, Maria",
	"dalla Vella, Marco",
	"degli Castelli, Lorenza",
	"di Francesco, Maria",
	"di Lampedusa, Tomasi Giuseppe",
	"du Page, Pierre",
	"da Silva, Jorge",
	"do Santo, Filipe",
	"dos Santos, Abilio",
	"das Costas, Adriana",
	"San Jose, Oscar",
	"Santa Gutierrez, Catalina",
	"Santos Bernal, Monica",

	"Ruiz y Picasso, Pablo Diego",
	"Puigdemont i Casamaj�, Carles",
	"da Silva dos Santos da Costa de Sousa, Jo�o Duarte",
	"da Silva Santos Costa e Sousa, Jo�o Duarte",

	"von Pappenhim, Hans",
	"von der Trave, Thomas",
	"zu Pappenhim, Hans",
	"von und zu Pappenhim, Hans",

	"van Haag, Bram",
	"der Haag, Jeroen",
	"ter Horst, Johanne",
	"den Haag, Sanne",
	"van de Horst, Laura",
	"van der Haag, Eva",
	"van den Haag, Willem",
	"van het Horst, Mees",
	"van Voorst tot Voorst, Henrik",
	"'sGravesande, Willem",
	"van 'sHertogenbosch, Gemeente",
	"van 'tHoen, Gemeente",

	"av Morgenstierne, Sigurd",
	"von Munthe af Morgenstierne, Maja",
	["Jonsson til Sudreim, Lars", "til Sudreim, Lars Jonsson"], # Split wrong without exception

	"DaSilva, James",
	"DuBois, Jack",
	"LaForge, Daniel",
	"LeFevre, Sally",
	"VanZandt, Kristine",

	"O Donoghue, Patrick",
	"� D�naill, Niall",
	"Ni Fhoghlua, Saoirse",
	"N� Fhoghlua, Saoirse",
	"Mac Donnchada, Michael",
	"Nic Fhoghlua, Saoirse",
	"Ua Donoghue, Michael",
	"Ua Duinn�n, P�draig",
	"Bean Ui Fhoghlua, Aisling",
	"Bean U� Fhoghlua, Aisling",
	"Bean Mhic Fhoghlua, Saoirse",
	"Fhoghlua, Saoirse Bean Other", # Incorrect name correctly not identified
	"Ui Fhoghlua, Saoirse",
	"U� Fhoghlua, Saoirse",
	"Mhic Fhoghlua, Saoirse",

	"� hAodha, Miche�l",
	"� hEigg�n, Miche�l",
	"� hIigg�n, Miche�l",
	"� hOigg�n, Miche�l",
	"� hUigg�n, Miche�l",
	"O hAodha, Miche�l",
	"O hEigg�n, Miche�l",
	"O hIigg�n, Miche�l",
	"O hOigg�n, Miche�l",
	"O hUigg�n, Miche�l",
	"� h�odha, Miche�l",
	"� h�igg�n, Miche�l",
	"� h�igg�n, Miche�l",
	"� h�igg�n, Miche�l",
	"� h�igg�n, Miche�l",
	"O h�odha, Miche�l",
	"O h�igg�n, Miche�l",
	"O h�igg�n, Miche�l",
	"O h�igg�n, Miche�l",
	"O h�igg�n, Miche�l",
	"� Hnotreal, Miche�l",
	"O Hnotreal, Miche�l",

	"ap Dafydd, Rhys",
	"ab Owain, Maredudd",
	"ferch Maredudd, Myfanwy",
	"verch Maredudd, Myfanwy",

	"El Ali, Camilla",
	"Al Musawi, Mariam",
	"el-Bayeh, Bazif",
	"al-Nassar, Nariman",
	"ut-Tahrir, Haqq",
	"ibn Hab, Aziz",
	"bin Hab, Charbel",
	"bint Aziz, Angela",
	"binti Othman, Fatima",
	"binte Othman, Nadia",

	# Right when technically unambiguous
	{ name => "ben Joseph, David", case => "ben Joseph, David", split => "ben Joseph, David" },
	{ name => "Peters, John Ben", case => "Peters, John Ben", split => "Peters, John Ben" },
	# Right sometimes when technically ambiguous
	{ name => "John Ben Peters", case => "John Ben Peters", split => "Peters, John Ben" },
	"Peters, John Ben",
	# Wrong sometimes when technically ambiguous
	{ name => "David ben Joseph", case => "David Ben Joseph", split => "Joseph, David Ben" },
	# Right when practically unambiguous (presence of v' and/or ha-)
	{ name => "David ben Joseph v'Rachel", case => "David ben Joseph v'Rachel", split => "ben Joseph v'Rachel, David" },
	{ name => "David ben Joseph v' Rachel", case => "David ben Joseph v' Rachel", split => "ben Joseph v' Rachel, David" },
	{ name => "David ben Joseph ha-Kohein", case => "David ben Joseph ha-Kohein", split => "ben Joseph ha-Kohein, David" },
	{ name => "David ben Joseph ha-Levi", case => "David ben Joseph ha-Levi", split => "ben Joseph ha-Levi, David" },
	{ name => "David ben Joseph ha-Rav", case => "David ben Joseph ha-Rav", split => "ben Joseph ha-Rav, David" },
	{ name => "David ben Joseph v'Rachel ha-Rav", case => "David ben Joseph v'Rachel ha-Rav", split => "ben Joseph v'Rachel ha-Rav, David" },

	"ben Joseph v'Rachel, David",
	"bat Moshe, Leah",
	"bat Moshe v'Rachel ha-Rav, Leah",
	"bat Mordecai v' Tzipporah, Devorah Rut",
	"mibeit Moshe v'Rachel ha-Levi, Leah",
	"mimishpachat Moshe v'Rachel ha-Kohein, Leah",

	"Te Whare, Natalie",

	"ka Nolwazi, Ayize",

	"Oso'ese",
	"Ya'akov",
	"Y'honatan",
	"Sh'mu'el",
	"Onosa\N{MODIFIER LETTER TURNED COMMA}i",
	"Tausa\N{RIGHT SINGLE QUOTATION MARK}afia",
	"Ka\N{RIGHT SINGLE QUOTATION MARK}ana\N{RIGHT SINGLE QUOTATION MARK}ana",
	"S\N{RIGHT SINGLE QUOTATION MARK}thembiso",

	"Tran, Van Man",
	"Morrison, Van",
	"Der, Joseph",

	'Pushkin, Alexander Sergeevich',
	'Dostoevsky, Fyodor Mikhailovich',
	'Akhmatova, Anna Andreevna',
	'Tolstoy, Lev Nikolayevich',
	'Dostoevsky, Fyodor Mikhailovich',
	'Akhmatova, Anna',
	'Gorenko, Anna Andreyevna',
	'Pavlova, Anna Pavlovna',
	'Pavlova, Anna Matveyevna'
);

# Test cases for nametrim() are two-element arrayrefs containing the input
# string and the expected result string.

my @nametrim_cases =
(
	[undef, undef],
	["", ""],
	["JohnSmith", "JohnSmith"],
	["John Smith", "John Smith"],
	["Smith, John", "Smith, John"],
	["    John       Smith    ", "John Smith"],
	["    Smith   ,  John     ", "Smith, John"],
	["    Smith   ,John     ", "Smith, John"],
	[" 		   Smith 	  , 	 John  	   ", "Smith, John"],
	["  Peter Smith - Jones  ", "Peter Smith-Jones"],
	[" Smith - Jones ,Peter ", "Smith-Jones, Peter"]
);

# Test cases for namecase_exception() are strings containing
# the exception. It can either be a family name, or an
# unambiguous full name: "Family_name, Given_names".

my @case_exception_cases =
(
	"d'Family, Given",
	"D'Family, Given",
	"D'family, Given",
	"d'family, Given",
	"d'FaMiLy, GiVeN",
	"Macdonald",
	"MacdonalD",
	"MacOther, Bruce",
	"mArrier D'uNiEnViLlE, aLiX",
	"MacDh�mhnaill",
	"NicDhonnchaidh"
);

# Test cases for namesplit_exceptions() are strings containing
# the exception. It must be a full name in unambiguous form:
# "Family_name, Given Names".

my @split_exception_cases =
(
	"Abdul Aziz, Jenny",
	"Ah Fat, Peter",
	"Ali Khan, Liban",
	"Assis de Queiroz, Vinicius",
	"Castano Mendoza, Luiza",
	"de Gois, Maria de Sousa",
	"Gautam Adhikari, Devi",
	"Marrier d\N{RIGHT SINGLE QUOTATION MARK}Unienville, Pierre", # Non-ASCII apostrophe
	"Nom de Nom\N{EN DASH}Nom, Pr�nom" # Non-ASCII dash
);

# Test preservation/non-preservation of non-ASCII apostrophe-like and
# hyphen-like characters (case and split). Each case is an arrayref. The
# first item is the case and split exception. The remaining items are cases
# that must match the exception.

my @nonascii_punctuation_cases =
(
	[
		"fAm d'Fam-Fam, Giv", # ASCII hyphen-dash
		"fAm d\N{RIGHT SINGLE QUOTATION MARK}Fam-Fam, Giv", # U+2019 Right Single Quotation Mark
		"fAm d\N{MODIFIER LETTER APOSTROPHE}Fam-Fam, Giv", # U+02BC Modifier Letter Apostrophe Unicode Character
		"fAm d\N{MODIFIER LETTER TURNED COMMA}Fam-Fam, Giv", # U+02BB Modifier Letter Turned Comma
		"fAm d'Fam\N{HEBREW PUNCTUATION MAQAF}Fam, Giv", # U+05BE Hebrew Punctuation Maqaf
		"fAm d\N{RIGHT SINGLE QUOTATION MARK}Fam\N{HYPHEN}Fam, Giv", # U+2010 Hyphen
		"fAm d\N{MODIFIER LETTER APOSTROPHE}Fam\N{NON-BREAKING HYPHEN}Fam, Giv", # U+2021 Non-Breaking Hyphen
		"fAm d\N{MODIFIER LETTER TURNED COMMA}Fam\N{EN DASH}Fam, Giv", # U+2013 En Dash
		"fAm d\N{MODIFIER LETTER TURNED COMMA}Fam\N{EM DASH}Fam, Giv" # U+2014 Em Dash
	],
	[
		"Ka\N{RIGHT SINGLE QUOTATION MARK}ana\N{RIGHT SINGLE QUOTATION MARK}ana, Giv", # Multiple
		"Ka'ana'ana, Giv",
		"Ka\N{MODIFIER LETTER APOSTROPHE}ana\N{MODIFIER LETTER APOSTROPHE}ana, Giv",
		"Ka\N{MODIFIER LETTER TURNED COMMA}ana\N{MODIFIER LETTER TURNED COMMA}ana, Giv"
	],
	[
		"Fim Onosa'i, Giv", # ASCII first
		"Fim Onosa\N{MODIFIER LETTER TURNED COMMA}i, Giv",
		"Fim Onosa\N{RIGHT SINGLE QUOTATION MARK}i, Giv",
		"Fim Onosa\N{MODIFIER LETTER APOSTROPHE}i, Giv"
	],
	[
		"Fam Onosa\N{MODIFIER LETTER TURNED COMMA}i, Giv", # ASCII not first
		"Fam Onosa\N{RIGHT SINGLE QUOTATION MARK}i, Giv",
		"Fam Onosa\N{MODIFIER LETTER APOSTROPHE}i, Giv",
		"Fam Onosa'i, Giv"
	]
);

# Test cases for normalize(). Each case is a full name in
# unambiguous format, used as a case exception and as a split
# exception.

my @normalization_cases =
(
	"Surplus f�mM�Ly, G�Bb�n",
	"Extra De\N{RIGHT SINGLE QUOTATION MARK} MaDiC�, MaRc�" # Test %split_starter as well
);

# Test cases for namejoin() are three-element arrayrefs containing the input
# family name and given names, and the expected resulting full name.

my @namejoin_cases =
(
	[undef, undef, undef],
	[undef, 'Giv', 'Giv'],
	['Fam', undef, 'Fam'],

	['Smith', 'Peter', 'Peter Smith'],
	['van Haag', 'Bram', 'Bram van Haag'],
	['Hu', 'Jintao', 'Jintao Hu'],
	['Lim', 'Yo Hwan', 'Yo Hwan Lim'],
	['Nguyen', 'Thi Minh Khai', 'Thi Minh Khai Nguyen']
);

# Disable test suites temporarily

#@test_cases = ();
#@nametrim_cases = ();
#@case_exception_cases = ();
#@split_exception_cases = ();
#@nonascii_punctuation_cases = ();
#@normalization_cases = ();
#@namejoin_cases = ();

# Calculate the number of test cases so that prove can display
# "currenttest/totaltests" while the tests are running, rather
# than "currenttest/?". But it's probably not worth the effort.

my $num_undef = scalar grep { !defined } @test_cases;
my $num_list = scalar grep { defined && (ref eq 'ARRAY' || /, /) } @test_cases;
my $num_hash = scalar grep { defined && (ref eq 'HASH') } @test_cases;
my $num_given = scalar(@test_cases) - $num_list - $num_hash - $num_undef;
my $num_nametrim = scalar @nametrim_cases;
my $num_defaults = 6;
my $num_bad_case_exception = 3;
my $num_individual_case_exception = scalar grep { /, / } @case_exception_cases;
my $num_generic_case_exception = scalar grep { !/, / } @case_exception_cases;
my $num_bad_split_exception = 4;
my $num_split_exception = scalar @split_exception_cases;
my $num_nonascii_punctuation_cases = sum 0, map { scalar(@{$_}) - 1 } @nonascii_punctuation_cases;
my $num_normaliation_cases = scalar @normalization_cases;
my $num_namejoin_cases = scalar @namejoin_cases;

plan tests =>
	$num_undef * 5 +
	$num_list * 27 +
	$num_hash * 6 +
	$num_given * 15 +
	$num_nametrim * 1 +
	$num_defaults +
	$num_bad_case_exception +
	$num_individual_case_exception * 16 +
	$num_generic_case_exception * 7 +
	$num_bad_split_exception +
	$num_split_exception * 2 +
	$num_nonascii_punctuation_cases * 4 +
	$num_normaliation_cases * 24 +
	$num_namejoin_cases * 1 +
	$nowarnings;

# Run normalize first, before $namecase_exceptions_re is defined.
# Just for branch coverage. It has no effect yet/here.

use Unicode::Normalize qw(NFD NFC);
normalize(\&NFC);

# Test many cases (correct or only split wrong or case and split wrong)

for my $case (@test_cases)
{
	if (!defined $case)
	{
		is namecase($case), undef, 'namecase: undef';
		is gnamecase($case), undef, 'gnamecase: undef';
		is fnamecase($case), undef, 'fnamecase: undef';
		is namesplit($case), undef, 'namesplit: undef';
		cmp_deeply [nameparts($case)], [], 'nameparts: undef';
	}
	elsif (ref($case) eq 'ARRAY' || $case =~ /,/)
	{
		# An array ref contains the test name and the expected split failure
		my $expected_failure = undef;
		($case, $expected_failure) = @$case if ref($case) eq 'ARRAY';

		my ($f, $g) = split /, /, $case;

		my $u1 = "$f, $g"; # Unambiguous
		my $u2 = uc $u1;
		my $u3 = lc $u1;
		is namecase($u1), $u1, "namecase $u1 [$case]";
		is namecase($u2), $u1, "namecase $u2 [$case]";
		is namecase($u3), $u1, "namecase $u3 [$case]";

		my $a1 = "$g $f"; # Ambiguous
		my $a2 = uc $a1;
		my $a3 = lc $a1;
		is namecase($a1), $a1, "namecase $a1 [$case]";
		is namecase($a2), $a1, "namecase $a2 [$case]";
		is namecase($a3), $a1, "namecase $a3 [$case]";

		my $g1 = $g;
		my $g2 = uc $g;
		my $g3 = lc $g;
		is gnamecase($g1), $g1, "gnamecase $g1 [$case]";
		is gnamecase($g2), $g1, "gnamecase $g2 [$case]";
		is gnamecase($g3), $g1, "gnamecase $g3 [$case]";

		my $f1 = $f;
		my $f2 = uc $f;
		my $f3 = lc $f;
		is fnamecase($f1), $f1, "fnamecase $f1 [$case]";
		is fnamecase($f2), $f1, "fnamecase $f2 [$case]";
		is fnamecase($f3), $f1, "fnamecase $f3 [$case]";

		is fnamecase($f1, $g1), $f1, "fnamecase $f1, $g1 [$case]"; # Makes no difference without full name case exceptions
		is fnamecase($f2, $g2), $f1, "fnamecase $f2, $g2 [$case]";
		is fnamecase($f3, $g3), $f1, "fnamecase $f3, $g3 [$case]";

		is namesplit($u1), $u1, "namesplit $u1 [$case]";
		is namesplit($u2), $u1, "namesplit $u2 [$case]";
		is namesplit($u3), $u1, "namesplit $u3 [$case]";

		my $exp = ($expected_failure) ? $expected_failure : $u1;

		is namesplit($a1), $exp, "namesplit $a1 [$case]";
		is namesplit($a2), $exp, "namesplit $a2 [$case]";
		is namesplit($a3), $exp, "namesplit $a3 [$case]";

		cmp_deeply [nameparts($u1)], [$f, $g], "nameparts $u1 [$case]";
		cmp_deeply [nameparts($u2)], [$f, $g], "nameparts $u2 [$case]";
		cmp_deeply [nameparts($u3)], [$f, $g], "nameparts $u3 [$case]";

		cmp_deeply [nameparts($a1)], [split /, /, $exp], "nameparts $a1 [$case]";
		cmp_deeply [nameparts($a2)], [split /, /, $exp], "nameparts $a2 [$case]";
		cmp_deeply [nameparts($a3)], [split /, /, $exp], "nameparts $a3 [$case]";
	}
	elsif (ref($case) eq 'HASH')
	{
		my $name = $case->{name};
		my $ncase = $case->{case};
		my $nsplit = $case->{split};

		my $n1 = $name;
		my $n2 = uc $name;
		my $n3 = lc $name;

		is namecase($n1), $ncase, "namecase $n1 [$ncase - expect wrong]";
		is namecase($n2), $ncase, "namecase $n2 [$ncase - expect wrong]";
		is namecase($n3), $ncase, "namecase $n3 [$ncase - expect wrong]";

		is namesplit($n1), $nsplit, "namesplit $n1 [$ncase - expect wrong]";
		is namesplit($n2), $nsplit, "namesplit $n2 [$ncase - expect wrong]";
		is namesplit($n3), $nsplit, "namesplit $n3 [$ncase - expect wrong]";
	}
	else
	{
		my $n1 = $case;
		my $n2 = uc $case;
		my $n3 = uc $case;

		is namecase($n1), $n1, "namecase $n1";
		is namecase($n2), $n1, "namecase $n2";
		is namecase($n3), $n1, "namecase $n3";

		is gnamecase($n1), $n1, "gnamecase $n1";
		is gnamecase($n2), $n1, "gnamecase $n2";
		is gnamecase($n3), $n1, "gnamecase $n3";

		is fnamecase($n1), $n1, "fnamecase $n1";
		is fnamecase($n2), $n1, "fnamecase $n2";
		is fnamecase($n3), $n1, "fnamecase $n3";

		is namesplit($n1), $n1, "namesplit $n1";
		is namesplit($n2), $n1, "namesplit $n2";
		is namesplit($n3), $n1, "namesplit $n3";

		cmp_deeply [nameparts($n1)], (length $n1) ? [$n1] : [], "nameparts $n1";
		cmp_deeply [nameparts($n2)], (length $n1) ? [$n1] : [], "nameparts $n2";
		cmp_deeply [nameparts($n3)], (length $n1) ? [$n1] : [], "nameparts $n3";
	}
}

# Test nametrim

for my $case (@nametrim_cases)
{
	my ($in, $out) = @{$case};
	is nametrim($in), $out, "nametrim '@{[$in // 'undef']}'";
}

# Test defaulting to $_

$_ = "JOHN SMITH";
is namecase(), 'John Smith', 'namecase $_';
$_ = "SARA";
is gnamecase(), 'Sara', 'gnamecase $_';
$_ = "JONES";
is fnamecase(), 'Jones', 'fnamecase $_';
$_ = "MARY PETERS";
is namesplit(), 'Peters, Mary', 'namesplit $_';
$_ = "JEAN JEFFRIES";
cmp_deeply [nameparts()], ['Jeffries', 'Jean'], 'nameparts $_';
$_ = "    Peters   -   Smith   ,John    ";
is nametrim(), "Peters-Smith, John", 'nametrim $_';

# Test case_exception

is namecase_exception(), 0, "namecase_exception: noargs";
is namecase_exception(undef), 0, "namecase_exception: undef";
is namecase_exception(""), 0, "namecase_exception: empty";

for my $case (@case_exception_cases)
{
	my ($family, $given) = split /, /, $case;

	if (defined $given) # Individual case exception
	{
		# Get the default values
		my $old_family = namecase($family, 'family');
		my $old_full = namecase($case, 'full');
		my $old_other = namecase("$family, AnyBody", 'full');
		my $old_family_plus = fnamecase($family, $given);
		my $old_family_plus_other = fnamecase($family, 'AnyBody');

		# Add the exception
		is namecase_exception($case), 1, "namecase_exception: $case";

		# Get the corresponding new values
		my $new_family = namecase($family, 'family');
		my $new_full = namecase($case, 'full');
		my $new_other = namecase("$family, AnyBody", 'full');

		my $new_family_plus_given_expected = (split /, /, $case)[0]; # Family part of the exception
		my $new_family_plus_given = fnamecase($family, $given);
		my $new_family_plus_other = fnamecase($family, 'AnyBody');

		# Check that only the right ones are affected
		is $new_family, $old_family, "namecase_exception($case): family [$new_family] should be [$old_family]";
		is $new_full, $case, "namecase_exception($case): full [$new_full] should be [$case]";
		is $new_other, $old_other, "namecase_exception($case): other [$new_other] should be [$old_other]";
		is $new_family_plus_given, $new_family_plus_given_expected, "namecase_exception($case), fnamecase [$new_family_plus_given] should be [$new_family_plus_given_expected]";
		is $new_family_plus_other, $old_family_plus_other, "namecase_exception($case), fnamecase [$new_family_plus_other] should be [$old_family_plus_other]";

		# Do the same with all uppercase
		$new_family = namecase(uc $family, 'family');
		$new_full = namecase(uc $case, 'full');
		$new_other = namecase(uc "$family, AnyBody", 'full');

		$new_family_plus_given = fnamecase(uc $family, uc $given);
		$new_family_plus_other = fnamecase(uc $family, uc 'AnyBody');

		is $new_family, $old_family, "namecase_exception($case): family [$new_family] should be [$old_family]";
		is $new_full, $case, "namecase_exception($case): full [$new_full] should be [$case]";
		is $new_other, $old_other, "namecase_exception($case): other [$new_other] should be [$old_other]";
		is $new_family_plus_given, $new_family_plus_given_expected, "namecase_exception($case), fnamecase [$new_family_plus_given] should be [$new_family_plus_given_expected]";
		is $new_family_plus_other, $old_family_plus_other, "namecase_exception($case), fnamecase [$new_family_plus_other] should be [$old_family_plus_other]";

		# Do the same with all lowercase
		$new_family = namecase(lc $family, 'family');
		$new_full = namecase(lc $case, 'full');
		$new_other = namecase(lc "$family, AnyBody", 'full');

		$new_family_plus_given = fnamecase(uc $family, uc $given);
		$new_family_plus_other = fnamecase(uc $family, uc 'AnyBody');

		is $new_family, $old_family, "namecase_exception($case): family [$new_family] should be [$old_family]";
		is $new_full, $case, "namecase_exception($case): full [$new_full] should be [$case]";
		is $new_other, $old_other, "namecase_exception($case): other [$new_other] should be [$old_other]";
		is $new_family_plus_given, $new_family_plus_given_expected, "namecase_exception($case), fnamecase [$new_family_plus_given] should be [$new_family_plus_given_expected]";
		is $new_family_plus_other, $old_family_plus_other, "namecase_exception($case), fnamecase [$new_family_plus_other] should be [$old_family_plus_other]";
	}
	else
	{
		# Get the default values
		my $old_family = namecase($family, 'family');
		my $old_full = namecase("$family, AnyBody", 'full');

		# Add the exception
		is namecase_exception($case), 1, "namecase_exception: $case";

		# Get the corresponding new values
		my $new_family = namecase($family, 'family');
		my $new_full_expected = "$family, Anybody";
		my $new_full = namecase($new_full_expected, 'full');

		# Check that all uses are affected
		is $new_family, $family, "namecase_exception($case): family ($new_family) should be ($family)";
		is $new_full, $new_full_expected, "namecase_exception($case): other ($new_full) should be ($new_full_expected)";

		# Do the same with all uppercase
		$new_family = namecase(uc $family, 'family');
		$new_full = namecase(uc $new_full_expected, 'full');
		is $new_family, $family, "namecase_exception(uc $case): family ($new_family) should be ($family)";
		is $new_full, $new_full_expected, "namecase_exception(uc $case): other ($new_full) should be ($new_full_expected)";

		# Do the same with all lowercase
		$new_family = namecase(lc $family, 'family');
		$new_full = namecase(lc $new_full_expected, 'full');
		is $new_family, $family, "namecase_exception(lc $case): family ($new_family) should be ($family)";
		is $new_full, $new_full_expected, "namecase_exception(lc $case): other ($new_full) should be ($new_full_expected)";
	}
}

# Test split_exception

is namesplit_exception(), 0, "namesplit_exception: noargs";
is namesplit_exception(undef), 0, "namesplit_exception: undef";
is namesplit_exception(""), 0, "namesplit_exception: empty";
is namesplit_exception("no comma"), 0, "namesplit_exception: not an unambiguous full name";

for my $case (@split_exception_cases)
{
	my ($family, $given) = split /, /, $case;
	my $natural = "$given $family";
	my $natural_other = "$given Anybody";

	my $old_split_given = namesplit($natural);
	my $old_split_other = namesplit($natural_other);

	namesplit_exception($case);

	is namesplit($natural), $case, "namesplit_exception($case) ($natural)";
	is namesplit($natural_other), $old_split_other, "namesplit_exception($case) ($natural_other)";
}

# Test non-ASCII apostrophe/hyphen preservation/replacement for case and split

for my $case (@nonascii_punctuation_cases)
{
	my $first = shift @{$case};

	namecase_exception($first);
	namesplit_exception($first);

	for my $next (@{$case})
	{
		my ($f, $g) = split /, /, $next;
		my $natural = "$g $f";

		is namecase($next), $first, "nonascii_punctuation namecase_exception($first): $next";
		is namecase($natural), $first, "nonascii_punctuation namecase_exception($first): $natural";

		is namesplit($next), $first, "nonascii_punctuation namesplit_exception($first): $next";
		is namesplit($natural), $first, "nonascii_punctuation namesplit_exception($first): $natural";
	}
}

# Test normalize

for my $case (@normalization_cases)
{
	my ($f, $g) = split /, /, $case;

	my $nfc_case = NFC($case);
	my $nfd_case = NFD($case);
	my $nfc_ucase = NFC(uc $case);
	my $nfd_ucase = NFD(uc $case);
	my $nfc_lcase = NFC(lc $case);
	my $nfd_lcase = NFD(lc $case);

	my $case_default = namecase($case);
	my $split_default = namecase($case);
	my $nfc_case_default = namecase($nfc_case);
	my $nfd_case_default = namecase($nfd_case);
	my $nfc_split_default = namesplit($nfc_case);
	my $nfd_split_default = namesplit($nfd_case);

	# Start with a known normalization (NFC matches, NFD doesn't)

	normalize(\&NFC);
	namecase_exception($nfc_case);
	namesplit_exception($nfc_case);

	is namecase($nfc_case), $nfc_case, "normalize(NFC) namecase(NFC $nfc_case)";
	is namecase($nfc_ucase), $nfc_case, "normalize(NFC) namecase(NFC $nfc_ucase)";
	is namecase($nfc_lcase), $nfc_case, "normalize(NFC) namecase(NFC $nfc_lcase)";

	is namesplit($nfc_case), $nfc_case, "normalize(NFC) namesplit(NFC $nfc_case)";
	is namesplit($nfc_ucase), $nfc_case, "normalize(NFC) namesplit(NFC $nfc_ucase)";
	is namesplit($nfc_lcase), $nfc_case, "normalize(NFC) namesplit(NFC $nfc_lcase)";

	is namecase($nfd_case), $nfd_case_default, "normalize(NFC) namecase(NFD $nfd_case)";
	is namecase($nfd_ucase), $nfd_case_default, "normalize(NFC) namecase(NFD $nfd_ucase)";
	is namecase($nfd_lcase), $nfd_case_default, "normalize(NFC) namecase(NFD $nfd_lcase)";

	is namesplit($nfd_case), $nfd_split_default, "normalize(NFC) namesplit(NFD $nfd_case)";
	is namesplit($nfd_ucase), $nfd_split_default, "normalize(NFC) namesplit(NFD $nfd_ucase)";
	is namesplit($nfd_lcase), $nfd_split_default, "normalize(NFC) namesplit(NFD $nfd_lcase)";

	# Renormalize and repeat (NFC doesn't match, NFD does)

	normalize(\&NFD);

	is namecase($nfc_case), $nfc_case_default, "normalize(NFD) namecase(NFC $nfc_case)";
	is namecase($nfc_ucase), $nfc_case_default, "normalize(NFD) namecase(NFC $nfc_ucase)";
	is namecase($nfc_lcase), $nfc_case_default, "normalize(NFD) namecase(NFC $nfc_lcase)";

	is namesplit($nfc_case), $nfc_split_default, "normalize(NFD) namesplit(NFC $nfc_case)";
	is namesplit($nfc_ucase), $nfc_split_default, "normalize(NFD) namesplit(NFC $nfc_ucase)";
	is namesplit($nfc_lcase), $nfc_split_default, "normalize(NFD) namesplit(NFC $nfc_lcase)";

	is namecase($nfd_case), $nfd_case, "normalize(NFD) namecase(NFD $nfd_case)";
	is namecase($nfd_ucase), $nfd_case, "normalize(NFD) namecase(NFD $nfd_ucase)";
	is namecase($nfd_lcase), $nfd_case, "normalize(NFD) namecase(NFD $nfd_lcase)";

	is namesplit($nfd_case), $nfd_case, "normalize(NFD) namesplit(NFD $nfd_case)";
	is namesplit($nfd_ucase), $nfd_case, "normalize(NFD) namesplit(NFD $nfd_ucase)";
	is namesplit($nfd_lcase), $nfd_case, "normalize(NFD) namesplit(NFD $nfd_lcase)";
}

# Test namejoin

for my $case (@namejoin_cases)
{
	my ($f, $g, $expected) = @{$case};

	is namejoin($f, $g), $expected, "namejoin(@{[$f // 'undef']}, @{[$g // 'undef']})";
}

# vim:set fenc=latin1:
# vi:set ts=4 sw=4:
