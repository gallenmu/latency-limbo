#!/usr/bin/env python3

import argparse
import binascii
import cProfile
import logging
import sys
import types

from pypacker import ppcap

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

# patching not necessary any more
# Moongen pcap patching
#def moongen_pcap_cb_read(self):
#
#    buf = self._fh.read(16)
#    if not buf:
#        raise StopIteration
#
#    d = self._callback_unpack_meta(buf)
#    buf = self._fh.read(d[2])
#    x = self._callback_unpack_meta(buf[-16:])
#
#    return x[3] * 1000000000 + x[2], buf[:-16]

def remove_checksums(buf):
    ipv4 = 0
    ipv6 = 0
    other = 0

    ipv4_no_header = 0
    tcp = 0
    udp = 0
    icmp = 0
    other_l4 = 0

    if buf[12:14] == b'\x08\x00':
        ipv4 = 1

        if buf[14:15] != b'\x45':
            ipv4_no_header = 1
            return buf, ipv4, ipv6, other, ipv4_no_header, tcp, udp, icmp, other_l4

        #frag_id = buf[14:20]
        #print(frag_id)
        #if frag_id != b'\x00\x00':
        #    inc_ip4_fragmented()
        #logging.info('ipv4 %s', buf[12:14])
        #logging.info('protocol %s', buf[23:24])
        #logging.info('ip chksum %s', buf[24:26])

        protocol = buf[23:24]
        if protocol == b'\x06': # TCP
            tcp = 1
            buf =  buf[:24] + b"\0\0" + buf[26:50] + b"\0\0" + buf[52:]
            return buf, ipv4, ipv6, other, ipv4_no_header, tcp, udp, icmp, other_l4

        elif protocol == b'\x11': # UDP
            udp = 1
            buf = buf[:24] + b"\0\0" + buf[26:40] + b"\0\0" + buf[42:]
            return buf, ipv4, ipv6, other, ipv4_no_header, tcp, udp, icmp, other_l4

        elif protocol == b'\x01': # ICMP
            icmp = 1
        else: # other l4 proto
            other_l4 = 1
            logging.debug("Detected unknown IPv4 payload with protocol number: %s", protocol)

    elif buf[12:14] == b'\x86\xdd':
        ipv6 = 1
    else:
        other = 1

    return buf, ipv4, ipv6, other, ipv4_no_header, tcp, udp, icmp, other_l4

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("pcap")
    parser.add_argument("--profile")

    args = parser.parse_args()

    #ppcap.pcap_cb_read = moongen_pcap_cb_read

    pcap = ppcap.Reader(args.pcap)

    #pcap.__next__ = types.MethodType(moongen_pcap_cb_read, pcap)
    #pcap.read = types.MethodType(moongen_pcap_cb_read, pcap)

    stats_ipv4 = 0
    stats_ipv6 = 0
    stats_other = 0
    stats_ipv4_no_header = 0
    stats_tcp = 0
    stats_udp = 0
    stats_icmp = 0
    stats_other_l4 = 0

    profile = None
    if args.profile:
        profile = cProfile.Profile()
        profile.enable()

    try:
        for ts, buf in pcap:
            xbuf, ipv4, ipv6, other, ipv4_no_header, tcp, udp, icmp, other_l4 = remove_checksums(buf[:64])

            stats_ipv4 += ipv4
            stats_ipv6 += ipv6
            stats_other += other
            stats_ipv4_no_header += ipv4_no_header
            stats_tcp += tcp
            stats_udp += udp
            stats_icmp += icmp
            stats_other_l4 += other_l4

            try:
                # remove mac, since they cannot match in the VM setup
                sys.stdout.buffer.write(b"%d\t\\\\x%s\n" % (ts, binascii.b2a_hex(xbuf[12:])))
            except BrokenPipeError as e:
                logging.info("Broken Pipe (reader died?), exiting")
                break
    # suppress error when executing in python 3.7
    # changed behavior of StopIteration
    except RuntimeError:
        pass

    if profile:
        profile.disable()
        profile.dump_stats(args.profile)

    logging.info("IPv4: %i [!options: %i] (TCP: %i, UDP: %i, ICMP: %i, other: %i), IPv6: %i, other: %i",
            stats_ipv4, stats_ipv4_no_header, stats_tcp, stats_udp, stats_icmp, stats_other_l4, stats_ipv6, stats_other)


if __name__ == "__main__":
    main()
