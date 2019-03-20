#!/usr/bin/perl
#
# Copyright (C) 2006 by Jacob Cunningham.  All rights reserved
# This program is free software; you can redistribute it and/or modify it 
# under the terms of the GNU General Public License as published by the 
# Free Software Foundation; either version 2 of the License, or (at your 
# option) any later version.
#
# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
# for more details.
#
# You should have received a copy of the GNU General Public License along 
# with this program; if not, write to the Free Software Foundation, Inc., 
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR ANY PARTICULAR PURPOSE.
# IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA, OR PROFITS OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Windows LNK file parser - Jacob Cunningham - jakec76@users.sourceforge.net
# Based on the contents of the document:
# http://www.i2s-lab.com/Papers/The_Windows_Shortcut_File_Format.pdf
# v1.0

use strict;
no warnings;

#-------------------------------------------------------------------------\
# VARIABLES
#
my ($flag_bit,%flag_hash,$flag_cnt,$vol_bit0,$vol_bit1,$next_loc);
my ($flag_bit0,$flag_bit1,$flag_bit2,$flag_bit3,$flag_bit4,$flag_bit5,$flag_bit6);
my (%file_hash,$file_att_cnt,$file_bit,$file_attrib_val);
my (%Show_wnd_hash,%vol_type_hash);

# I made the tag names up based on the docs
# Hash of LINK FLAG VALUES
$flag_hash{0}->{1} = "HAS SHELLIDLIST";
$flag_hash{0}->{0} = "NO SHELLIDLIST";
$flag_hash{1}->{1} = "POINTS TO FILE/DIR";
$flag_hash{1}->{0} = "NOT POINT TO FILE/DIR";
$flag_hash{2}->{1} = "HAS DESCRIPTION";
$flag_hash{2}->{0} = "NO DESCRIPTION";
$flag_hash{3}->{1} = "HAS RELATIVE PATH STRING";
$flag_hash{3}->{0} = "NO RELATIVE PATH STRING";
$flag_hash{4}->{1} = "HAS WORKING DIRECTORY";
$flag_hash{4}->{0} = "NO WORKING DIRECTORY";
$flag_hash{5}->{1} = "HAS CMD LINE ARGS";
$flag_hash{5}->{0} = "NO CMD LINE ARGS";
$flag_hash{6}->{1} = "HAS CUSTOM ICON";
$flag_hash{6}->{0} = "NO CUSTOM ICON";

# HASH of FileAttributes
$file_hash{0}->{1} = "READ ONLY TARGET";
$file_hash{1}->{1} = "HIDDEN TARGET";
$file_hash{2}->{1} = "SYSTEM FILE TARGET";
$file_hash{3}->{1} = "VOLUME LABEL TARGET (not possible)";
$file_hash{4}->{1} = "DIRECTORY TARGET";
$file_hash{5}->{1} = "ARCHIVE";
$file_hash{6}->{1} = "NTFS EFS";
$file_hash{7}->{1} = "NORMAL TARGET";
$file_hash{8}->{1} = "TEMP. TARGET";
$file_hash{9}->{1} = "SPARSE TARGET";
$file_hash{10}->{1} = "REPARSE POINT DATA TARGET";
$file_hash{11}->{1} = "COMPRESSED TARGET";
$file_hash{12}->{1} = "TARGET OFFLINE";

#Hash of ShowWnd values
$Show_wnd_hash{0} = "SW_HIDE";
$Show_wnd_hash{1} = "SW_NORMAL";
$Show_wnd_hash{2} = "SW_SHOWMINIMIZED";
$Show_wnd_hash{3} = "SW_SHOWMAXIMIZED";
$Show_wnd_hash{4} = "SW_SHOWNOACTIVE";
$Show_wnd_hash{5} = "SW_SHOW";
$Show_wnd_hash{6} = "SW_MINIMIZE";
$Show_wnd_hash{7} = "SW_SHOWMINNOACTIVE";
$Show_wnd_hash{8} = "SW_SHOWNA";
$Show_wnd_hash{9} = "SW_RESTORE";
$Show_wnd_hash{10} = "SW_SHOWDEFAULT";

# Hash for Volume types
$vol_type_hash{0} = "Unknown";
$vol_type_hash{1} = "No root directory";
$vol_type_hash{2} = "Removable (Floppy,Zip,USB,etc.)";
$vol_type_hash{3} = "Fixed (Hard Disk)";
$vol_type_hash{4} = "Remote (Network Drive)";
$vol_type_hash{5} = "CD-ROM";
$vol_type_hash{6} = "RAM Drive";

#------------------------------------------------------------------------------\
# Open the file
if (!defined $ARGV[0]) {
  print_usage();
}
my $file = $ARGV[0];
print "\nLink File:  $ARGV[0]\n";
open (FH, "$file") || die "Can't open file $ARGV[0] for reading\n";
binmode(FH);

# Check header is 4c
# This is actually 4 bytes long I'm only reading the first 1byte
my $header = read_unpack(0,1);
if ($header ne "4c") {
  print "Invalid Lnk file header\n";
  exit;
}

# Optional
# Check GUID 16bytes @ 4h
#my $guid = read_unpack(4,16);
#print "GUID: $guid\n";

#Flags 4bytes (I'm only reading 1st) @14h = 20d
 my $flags = read_unpack_bin(20,1);
 print "Link Flags: ";
 $flag_cnt = 0;
 while ($flag_cnt < 7) {
   $flag_bit = substr($flags,$flag_cnt,1);
   print " $flag_hash{$flag_cnt}->{$flag_bit} |";
   #Check flag bit0
   if (($flag_cnt eq "0") && ($flag_bit eq "1")) {
        $flag_bit0 = 1;
   }
    # check flag bit1
    if (($flag_cnt eq "1") && ($flag_bit eq "1")) {
        $flag_bit1 = 1;
    }
    # Check Description bit
    if (($flag_cnt eq "2") && ($flag_bit eq "1")) {
        $flag_bit2 = 1;
    }
    # Check Relative Path link
    if (($flag_cnt eq "3") && ($flag_bit eq "1")) {
        $flag_bit3 = 1;
    }
    # Check working dir
    if (($flag_cnt eq "4") && ($flag_bit eq "1")) {
        $flag_bit4 = 1;
    }
    # CMD line
    if (($flag_cnt eq "5") && ($flag_bit eq "1")) {
        $flag_bit5 = 1;
    }
    # ICON filename
    if (($flag_cnt eq "6") && ($flag_bit eq "1")) {
        $flag_bit6 = 1;
    }

   $flag_cnt++;
  } 
  print "\n";

# File Attributes 4bytes@18h = 24d
# Only a non-zero if "Flag bit 1" above is set to 1
#
if ($flag_bit1 eq "1") {
 my $file_attrib = read_unpack_bin(24,2);
 print "File Attributes: ";
 $file_att_cnt = 0;
 while ($file_att_cnt < 13) {
   $file_bit = substr($file_attrib,$file_att_cnt,1);
   print "$file_hash{$file_att_cnt}->{$file_bit}";
   $file_att_cnt++;
 }
 print "\n";
}

# Create time 8bytes @ 1ch = 28
my $ctime = read_unpack(28,8);
$ctime = hex(reverse_hex($ctime));
$ctime = MStime_to_unix($ctime);
print "Create Time: $ctime\n";

# Access time 8 bytes@ 0x24 = 36D
my $atime = read_unpack(36,8);
$atime = hex(reverse_hex($atime));
$atime = MStime_to_unix($atime);
print "Last Accessed time: $atime\n";

#Mod Time8b @ 0x2C = 44D

my $mtime = read_unpack(44,8);
$mtime = hex(reverse_hex($mtime));
$mtime = MStime_to_unix($mtime);
print  "Last Modified Time: $mtime\n";

#
#Target File length starts @ 34h = 52d
my $f_len = read_unpack(52,4);
$f_len = hex(reverse_hex($f_len));
print "Target Length: $f_len\n";

# Icon File info starts @ 38h = 56d
my $ico_num = read_unpack(56,4);
$ico_num = hex($ico_num);
print "Icon Index: $ico_num\n";


#ShowWnd val to pass to target
# Starts @3Ch = 60d 
my $show_wnd = read_unpack(60,1);
$show_wnd = hex($show_wnd);
print "ShowWnd: $show_wnd $Show_wnd_hash{$show_wnd}\n";

#Hot key
# Starts @40h = 64d 
my $hot_key = read_unpack(64,4);
$hot_key = hex($hot_key);
print "HotKey: $hot_key\n";



#----------------------------------------------------------------------\
# ItemID List
# Read size of item ID list
my $i_len = read_unpack(76,2);
$i_len = hex(reverse_hex($i_len));
#skip to end of list
my $end_of_list = (78 + $i_len);

#------------------------------------------------------------------------\
# FileInfo structure
#
my $struc_start = $end_of_list;
my $first_off_off = ($struc_start + 4);
my $vol_flags_off = ($struc_start + 8);
my $local_vol_off = ($struc_start + 12);
my $base_path_off = ($struc_start + 16);
my $net_vol_off = ($struc_start + 20);
my $rem_path_off = ($struc_start + 24);

# Structure length
my $struc_len = read_unpack($struc_start,4);
$struc_len = hex(reverse_hex($struc_len));
my $struc_end = ($struc_start + $struc_len);

# First offset after struct - Should be 1C under normal circumstances
my $first_off = read_unpack($first_off_off,1);

# File location flags
my $vol_flags = read_unpack_bin($vol_flags_off,1);
my $vol_flags = substr($vol_flags,0,2);
if ($vol_flags =~ /10/) {
  print "Target is on local volume\n"; 
   $vol_bit0 = 1;
   $vol_bit1 = 0;
}
if ($vol_flags =~ /01/) {
  print "Target is on Network share\n"; 
   $vol_bit1 = 1;
   $vol_bit0 = 0;
}
 
# Local volume table
# Random garbage if bit0 is clear in volume flags
if ($vol_bit0 eq "1") {
  # This is the offset of the local volume table within the 
  #File Info Location Structure
  my $loc_vol_tab_off = read_unpack($local_vol_off,4); 
  $loc_vol_tab_off = hex(reverse_hex($loc_vol_tab_off));

  # This is the asolute start location of the local volume table
  my $loc_vol_tab_start = ($loc_vol_tab_off + $struc_start);

  # This is the length of the local volume table
  my $local_vol_len = read_unpack(($loc_vol_tab_off + $struc_start),4);
  $local_vol_len = hex(reverse_hex($local_vol_len));

  # We now have enough info to
  # Calculate the end of the local volume table.
  my $local_vol_tab_end = ($loc_vol_tab_start + $local_vol_len);

  # This is the volume type
  my $curr_tab_offset = ($loc_vol_tab_off + $struc_start + 4);
  my $vol_type = read_unpack($curr_tab_offset,4);
  $vol_type = hex(reverse_hex($vol_type));
  print "Volume Type: $vol_type_hash{$vol_type}\n";

  # Volume Serial Number
  $curr_tab_offset = ($loc_vol_tab_off + $struc_start + 8);
  my $vol_serial = read_unpack($curr_tab_offset,4);
  $vol_serial = reverse_hex($vol_serial);
  print "Volume Serial: $vol_serial\n";

  # Get the location, and length of the volume label 
  # we should really read the vol_label_loc from offset Ch 
  my $vol_label_loc = ($loc_vol_tab_off + $struc_start + 16);
  my $vol_label_len = ($local_vol_tab_end - $vol_label_loc);
  my $vol_label = read_unpack_ascii($vol_label_loc,$vol_label_len);
  print "Vol Label: $vol_label\n";

#-------------------------------------------------
# This is the offset of the base path info within the
# File Info structure
# Random Garbage when bit0 is clear in volume flags
#
my $base_path_off = read_unpack($base_path_off,4);
$base_path_off = (hex(reverse_hex($base_path_off)));
$base_path_off = ($struc_start + $base_path_off);

# Read base path data upto NULL term 
my $bp_data = read_null_term($base_path_off);
print "Base Path: $bp_data\n";

}

#-------------------------------------------------
# Network Volume Table
if ($vol_bit1 eq "1") {
 $net_vol_off = hex(reverse_hex(read_unpack($net_vol_off,4)));
 $net_vol_off = ($struc_start + $net_vol_off);
 my $net_vol_len = read_unpack($net_vol_off,4);
 $net_vol_len = (hex(reverse_hex($net_vol_len)));

 # Network Share Name
 my $net_share_name_off = ($net_vol_off + 8);
 my $net_share_name_loc = hex(reverse_hex(read_unpack($net_share_name_off,4)));
 if ($net_share_name_loc  ne "20") 
	{ die "Error: NSN ofset should always be 14h\n"; }
 $net_share_name_loc = ($net_vol_off + $net_share_name_loc);
 my $net_share_name = read_null_term($net_share_name_loc);
 print "Network Share Name: $net_share_name\n";

 # Mapped Network Drive Info
 my $net_share_mdrive = ($net_vol_off + 12);
 my $net_share_mdrive = read_unpack($net_share_mdrive,4);
 $net_share_mdrive = (hex(reverse_hex($net_share_mdrive)));
 if ($net_share_mdrive ne "0") {
   $net_share_mdrive = ($net_vol_off + $net_share_mdrive);
   $net_share_mdrive = read_null_term($net_share_mdrive);
   print "Mapped Drive: $net_share_mdrive\n";
 }
}

#Remaining Path
my $rem_path_off = read_unpack($rem_path_off,4);
$rem_path_off = (hex(reverse_hex($rem_path_off)));
$rem_path_off = ($struc_start + $rem_path_off);
my $rem_data = read_null_term($rem_path_off);
print "(App Path:) Remaining Path: $rem_data\n";

# End of FileInfo Structure
#------------------------------------------------------------------------\
#
# The next starting location is the end of the structure
my $next_loc = $struc_end;
my $addnl_text;

# Description String
# present if bit2 is set in header flags.
if ($flag_bit2 eq "1") {
 ($addnl_text,$next_loc) = add_info("$next_loc");
 print "Description: $addnl_text\n";
 $next_loc = ($next_loc + 1);
}

# Relative Path
if ($flag_bit3 eq "1") {
 ($addnl_text,$next_loc) = add_info("$next_loc");
 print "Relative Path: $addnl_text\n";
 $next_loc = ($next_loc + 1);
}
# Working Dir
if ($flag_bit4 eq "1") {
 ($addnl_text,$next_loc) = add_info("$next_loc");
 print "Working Dir: $addnl_text\n";
 $next_loc = ($next_loc + 1);
}
# CMD Line
if ($flag_bit5 eq "1") {
($addnl_text,$next_loc) = add_info("$next_loc");
 print "Command Line: $addnl_text\n";
 $next_loc = ($next_loc + 1);
}
#Icon filename
my ($addnl_text,$next_loc) = add_info("$next_loc");
if ($flag_bit6 eq "1") {
 print "Icon filename: $addnl_text\n";
}

# END
exit;

#--------------------------------------------------------------------\
# Subroutines Below
#--------------------------------------------------------------------\
# 
sub add_info {
    my ($tmp_start_loc) = shift;
    my $tmp_len = (2 * hex(reverse_hex(read_unpack($tmp_start_loc,1))));
    $tmp_start_loc++;
    if ($tmp_len ne "0") {
     my $tmp_string = read_unpack_ascii($tmp_start_loc,$tmp_len);
     my $now_loc = tell();
     return($tmp_string,$now_loc);
    } else {
     my $now_loc = tell();
     my $tmp_string = "Null";
     return($tmp_string,$now_loc);
    }
}
#----------------------------------------------------------------------\
# Read N bytes, from location , unpack as HEX

sub read_unpack {
 my ($loc, $bites) = @_;
 my ($tmp_data);
  seek(FH,$loc,0) or
        die "Can't seek to $loc\n";
     read(FH,$tmp_data,$bites);
     $tmp_data = (unpack('H*', $tmp_data));
     return($tmp_data); 

}

#-------------------------------------------------------------------------\
# Read N bytes from specified location, unpack ASCII
sub read_unpack_ascii {
 my ($loc, $bites) = @_;
 my ($tmp_data);
  seek(FH,$loc,0) or
        die "Can't seek to $loc\n";
     read(FH,$tmp_data,$bites);
     $tmp_data = (unpack('A*', $tmp_data));
     return($tmp_data); 
}

#-------------------------------------------------------------------------\
# Unpack data to binary binary 
sub read_unpack_bin {
 my ($loc, $bites) = @_;
 my ($tmp_data);
  seek(FH,$loc,0) or
        die "Can't seek to $loc\n";
     read(FH,$tmp_data,$bites);
     $tmp_data = (unpack('b*', $tmp_data));
     return($tmp_data); 

}

#---------------------------------------------------------------------------\
# Convert MS FILETIME to Unix Epoch

sub MStime_to_unix {

 my $mstime_dec = shift;
 
 # The number of seconds between Unix/FILETIME epochs
 my $MSConversion = "11644473600";
 
 #Convert 100ms increments to Seconds.
 $mstime_dec = ($mstime_dec * .0000001);

 # Add difference in epochs
 $mstime_dec-=$MSConversion;

 # Get localtime
 my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($mstime_dec);
  my @weekdays_array = qw(Sun Mon Tue Wed Thur Fri Sat);
  my @month_array = qw(Jan Feb Mar Apr May Jun Jul Aug Sept Oct Nov Dec);

  $year += 1900; 
  $mon = sprintf("%02d",$mon);
  $mday = sprintf("%02d",$mday);
  $hour = sprintf("%02d",$hour);
  $min = sprintf("%02d",$min);
  $sec = sprintf("%02d",$sec);

  my $datestring = "$weekdays_array[$wday] $month_array[$mon] $mday $year $hour:$min:$sec";
  return $datestring;
}

#---------------------------------------------------------------------------\
# Reverse a hex string

sub reverse_hex {

 my $HEXDATE = shift;
 my @bytearry=();
 my $byte_cnt = 0;
 my $max_byte_cnt = 8;
 my $byte_offset = 0;
 while($byte_cnt < $max_byte_cnt) {
   my $tmp_str = substr($HEXDATE,$byte_offset,2);
    push(@bytearry,$tmp_str);
   $byte_cnt++;
   $byte_offset+=2;
 }
   return join('',reverse(@bytearry));
}
#---------------------------------------------------------------------------\
# Read a null terminated string from the specified location.

sub read_null_term {
    my ($loc) = shift;
    #Save old record seperator
    my $old_rs = $/;
    # Set new seperator to NULL term.
    $/ = "\0";
    seek(FH, $loc,0) or die "Can't seek to $loc\n";
    my $term_data = <FH>;
    chomp($term_data);
    # Reset 
    $/ = $old_rs;
    return($term_data);
}
#---------------------------------------------------------------------------\
# Print Usage info
sub print_usage {
  print "\nThis script parses Windows LNK files\n\n";
  print " Usage: $0 <filename.lnk> \n\n";
  exit;
}
#---------------------------------------------------------------------------\
