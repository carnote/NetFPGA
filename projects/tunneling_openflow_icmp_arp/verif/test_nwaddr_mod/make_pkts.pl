#!/usr/local/bin/perl -w
# make_pkts.pl
#
#
#

$delay = '@12us';
$batch = 0;

use NF::PacketGen;
use NF::PacketLib;
#use CPCI_Lib;
use SimLib;
#use NF21RouterLib;

use OpenFlowLib;
use NFUtils::SimplePacket;
use NFOpenFlowTester;

use reg_defines_tunneling_openflow_icmp_arp;

nf_set_environment( { PORT_MODE => 'PHYSICAL', MAX_PORTS => 4 } );
nf_add_port_rule(1, 'UNORDERED');
nf_add_port_rule(2, 'UNORDERED');
nf_add_port_rule(3, 'UNORDERED');
nf_add_port_rule(4, 'UNORDERED');

# use strict AFTER the $delay, $batch and %reg are declared
use strict;
use vars qw($delay $batch %reg);

#my %cpci_regs = CPCI_Lib::get_register_addresses();

# write 0 to CPCI_INTERRUPT_MASK_REG()
#nf_PCI_write32(0, $batch, CPCI_INTERRUPT_MASK_REG(), 0);

# Prepare the DMA and enable interrupts
prepare_DMA('@3.9us');
enable_interrupts(0);

####################################################################
# Setup the fields
#
my $outports = [0x40, 0x04, 0x10, 0x01];

my $fields_1 = 
  {NFUtils::SimplePacket::TRANSP_DST() => [0x1111],
   NFUtils::SimplePacket::TRANSP_SRC() => [0x2222],
   NFUtils::SimplePacket::IP_PROTO() => [0x12],
   NFUtils::SimplePacket::IP_DST() => [0x4222224],
   NFUtils::SimplePacket::IP_SRC() => [0x5111115],
   NFUtils::SimplePacket::ETH_TYPE() => [NFUtils::SimplePacket::ETH_TYPE_IP],
   NFUtils::SimplePacket::ETH_DST() => ["88:11:11:11:11:88"],
   NFUtils::SimplePacket::ETH_SRC() => ["77:11:11:11:11:77"],
   NFUtils::SimplePacket::SRC_PORT() => [0, 2, 4, 6],
   NFUtils::SimplePacket::IP_TOS() => [0],
   NFUtils::SimplePacket::VLAN_TAG() => [0x25ac],
   NFUtils::SimplePacket::PKT_TYPE() => [NFUtils::SimplePacket::PKT_TYPE_UDP]};

my $fields_2 = 
  {NFUtils::SimplePacket::TRANSP_DST() => [0x1111],
   NFUtils::SimplePacket::TRANSP_SRC() => [0x2222],
   NFUtils::SimplePacket::IP_PROTO() => [0x12],
   NFUtils::SimplePacket::IP_DST() => [0x12213443],
   NFUtils::SimplePacket::IP_SRC() => [0xa5c30fe1],
   NFUtils::SimplePacket::ETH_TYPE() => [NFUtils::SimplePacket::ETH_TYPE_IP],
   NFUtils::SimplePacket::ETH_DST() => ["88:11:11:11:11:88"],
   NFUtils::SimplePacket::ETH_SRC() => ["77:11:11:11:11:77"],
   NFUtils::SimplePacket::SRC_PORT() => [0, 2, 4, 6],
   NFUtils::SimplePacket::IP_TOS() => [0],
   NFUtils::SimplePacket::VLAN_TAG() => [0x25ac],
   NFUtils::SimplePacket::PKT_TYPE() => [NFUtils::SimplePacket::PKT_TYPE_UDP]};

my $table = OpenFlowTable->new('simulation' => 1);

my $delay_us = 8;

my $num_iter = 2;
my $num_pkts = 20;
my $num_table_entries = 6;
my $nf2_action_flag = 0x00c0; # OFPAT_SET_NW_SRC + OFPAT_SET_NW_DST
my $set_vlan_vid = 0;
my $set_vlan_pcp = 0;
my $set_dl_dst = 0;
my $set_dl_src = 0;
my $set_nw_dst = 0x12213443;
my $set_nw_src = 0xa5c30fe1;


####################################################################
# execute the simulation 1
# Send pkt with some IP src/dst, expect pkt with different IP src/dst value

$delay_us += NFOpenFlowTester::runRandomSim(\&NFOpenFlowTester::expDifferentPkt,
                                            NFOpenFlowTester::START_DELAY() => $delay_us,
					    NFOpenFlowTester::NUM_ITERATIONS() => $num_iter,
					    NFOpenFlowTester::NUM_PKTS() => $num_pkts,
					    NFOpenFlowTester::NUM_FLOW_ENTRIES() => $num_table_entries,
					    NFOpenFlowTester::TABLE() => $table,
					    NFOpenFlowTester::FLOW_ENTRY_FIELDS() => $fields_1,
					    NFOpenFlowTester::PKT_FIELDS() => $fields_1,
                                            NFOpenFlowTester::EXP_PKT_FIELDS() => $fields_2,
					    NFOpenFlowTester::OUTPUT_PORTS() => $outports,
                                            NFOpenFlowTester::NF2_ACTION_FLAG() => $nf2_action_flag,
                                            NFOpenFlowTester::SET_VLAN_VID() => $set_vlan_vid,
                                            NFOpenFlowTester::SET_VLAN_PCP() => $set_vlan_pcp,
                                            NFOpenFlowTester::SET_DL_SRC() => $set_dl_src,
                                            NFOpenFlowTester::SET_DL_DST() => $set_dl_dst,
                                            NFOpenFlowTester::SET_NW_SRC() => $set_nw_src,
                                            NFOpenFlowTester::SET_NW_DST() => $set_nw_dst);

# *********** Finishing Up - need this in all scripts ! **********************
my $t = nf_write_sim_files();
print  "--- make_pkts.pl: Generated all configuration packets.\n";
printf "--- make_pkts.pl: Last packet enters system at approx %0d microseconds.\n",($t/1000);
if (nf_write_expected_files()) {
  die "Unable to write expected files\n";
}

nf_create_hardware_file('LITTLE_ENDIAN');
nf_write_hardware_file('LITTLE_ENDIAN');


