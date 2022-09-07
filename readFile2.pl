use strict;
use warnings;
use Getopt::Long qw< GetOptions >;

my $rules = {
    'rules_1' => {
        'regex' => {
            'more_than_4_digit' => qr/\d{5,}/,
            "block-number" => qr/(?:\d{1,})(?:[\W_]?)/,
        },
        'description' => 'block of numbers more than 4 numbers avoid alphabets'
    },
};

my %opts;
GetOptions( \%opts,
    'help|h',
    'input_file|i=s',
    'output_file|o=s',
    'rules_file|r=s',
    'debug|d',
    'start_position|s=i'
) or exit 1;

usage("Required Options Missing ") if $opts{help} || !$opts{input_file} || !$opts{output_file};
print_log("Running $0 with options: " . join(', ', map { "'$_' => '$opts{$_}'" } keys %opts)) if $opts{debug};

print_log("Reading rules from file: $opts{rules_file}") if $opts{rules_file} && $opts{debug};
open my $fh_in,'<', $opts{input_file} or print_log("Could not open input file $opts{input_file}: $!",undef,'ERROR');
open my $fh_out,'>',$opts{output_file} or print_log ("Could not open output file $opts{output_file}: $!",undef,'ERROR');


my $line_no = 1;
my $remove_cr_lf = qr/[\x0A\x0D]/;
my $start_pos    = $opts{start_position} // 103;
my $preserve_inp = qr/(.{$start_pos})/;

while( my $line = <$fh_in>)  {
    $line_no++;
    # remove leading and trailing whitespace
     chomp $line;
     #remove \r\n if file is using windows line ending
     $line =~ s/$remove_cr_lf//g;
    # print the line to output_file

     if(length($line) < $start_pos) {
        print $fh_out $line . "\n" if $line;
        next;
    };
    #get original line before we replace
    $line =~ s/$preserve_inp//;
    my $org_string = $1;

    #iterate on each rule
    my @rules;
    foreach my $rule (sort keys %{$rules}) {
        #get regex
        my $regex_map = $rules->{$rule}->{regex};
        #iterate on each regex
        foreach my $regex_name (sort keys %{$regex_map}) {
            #get regex
            my $regex = $regex_map->{$regex_name};
            if (lc(ref $regex) eq 'regexp'){
                if($line =~ s/$regex/"X" x length($&)/ge) {
                    print_log("Found Regex type : $regex_name '$line'",$line_no) if $opts{debug};
                    push @rules, $regex_name;
                }
            }
            #can execute code block as well
            if (lc(ref $regex) eq 'code'){
                print_log("Found Code ref type : $regex_name '$line'",$line_no) if $opts{debug};
                $line = &$regex($line);
                push @rules, $regex_name;
            }
        }

    }
    #no rule found
    if (scalar @rules < 1) {
        print_log("Could not find any regex rule '$line' ",$line_no,'WARN') if $opts{debug};
    }

    #log the rules
    print_log("Rules applied on line $line_no: " . join(', ', @rules),$line_no) if $opts{debug};
    # print the line to output_file
    print $fh_out $org_string.$line . "\n" if $org_string;
}
# 5. Anything greater than 4 Numerics should be masked. There can be spaces, hyphen, dot, underscore any special char (but not alpha char a-z or A-Z). We should consider that as number and mask/replace with static/predefined XXXX...doesnt have to be X for every number we replace.

# 6. If our search pattern hits an alpha char, then our masking rule stops, checks if more than 4, if more than 4 mask with XXXX, less than equal to 4...do not mask. Pattern masks resumes when it sees a number again.

print_log("output file: $opts{output_file}");
close $fh_in;
close $fh_out;
################################
### helper method section   ####
################################

sub print_log {
    my ( $msg, $line_no, $level) = @_;

    if(not defined $level) {
        $level = 'INFO';
    }

    $level = uc $level;

    my $str = scalar localtime()  . ' [' . $level . ']';
    $str .= ' [Line ' . $line_no . '] ' if $line_no;
    $str .= ' ' . $msg . "\n";; 

    print $str;

    exit 1 if $level eq 'ERROR';
}

sub usage {
    my $err = shift;
    $err //= '';
    my $msg = join ("\n",
        'Number Mask Script v1.0',
        '    used to mask the sensetive data from files ',
        'Options:',
        '    --help              print this usage msg',
        '    --input_file        full path of input_file to be masked',
        '    --output_file       full path of output_file to be masked',
        '    --rules_file        (optional)full path of rules file to be used note file must contain a hash of rules perl format
                                    every hash value will be regex or code ref',
        '    --start_position    (optional)start position of the string to be replaced note will count from 0
                                    default is 103',
        '    --debug             (optional) print debug messages',
        '
        example:
                perl mask_data.pl --input_file=/tmp/input.txt --output_file=/tmp/output.txt --rules_file=rules.txt
        example2:
                perl mask_data.pl --input_file=input.txt --output_file=output.txt',
        '',
        ''
    );
    print $err. $msg;
    exit 0;
}