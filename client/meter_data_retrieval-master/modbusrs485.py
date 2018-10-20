#!/usr/bin/env python
 
# Modbus uitlezen
# Apparaat: DDS238-1 ZN (KWh meter)
#
# Script gemaakt door S. Ebeltjes (domoticx.nl)
 
from __future__ import division
import pymodbus
import serial
import time
from pymodbus.pdu import ModbusRequest
from pymodbus.client.sync import ModbusSerialClient as ModbusClient #initialize a serial RTU client instance
from pymodbus.transaction import ModbusRtuFramer
 
from pymodbus.constants import Endian              # Nodig voor 32-bit float getallen (2 registers / 4 bytes)
from pymodbus.payload import BinaryPayloadDecoder  # Nodig voor 32-bit float getallen (2 registers / 4 bytes)
from pymodbus.payload import BinaryPayloadBuilder  # Nodig om 32-bit floats te schrijven naar register
 
method = "rtu"
port = "/dev/ttyUSB0"
baudrate = 9600
stopbits = 1
bytesize = 8
parity = "N"
timeout = 1
retries = 2
 
try:
  client = ModbusClient(method = method, port = port, stopbits = stopbits, bytesize = bytesize, parity = parity, baudrate = baudrate, timeout = timeout, retries = retries)
  connection = client.connect()
except:
  print "Modbus connection error / DDS238"


while True:
  appid = 1
  data = client.read_holding_registers(0, 2, unit=appid)
  dds238_kwh_L = data.registers[0]
  dds238_kwh_H = data.registers[1] / 100
  print ("Total kWh: " , dds238_kwh_L + dds238_kwh_H)
  data1 = client.read_holding_registers(8, 2, unit=appid)
  dds238_export_kwh_L = data1.registers[0]
  dds238_export_kwh_H = data1.registers[1] / 100
  print ("Export kWh: " , dds238_export_kwh_L + dds238_export_kwh_H)
  data2 = client.read_holding_registers(10, 2, unit=appid)
  dds238_import_kwh_L = data2.registers[0]
  dds238_import_kwh_H = data2.registers[1] / 100
  print ("Import kWh: " , dds238_import_kwh_L + dds238_import_kwh_H)
  data3 = client.read_holding_registers(12, 1, unit=appid)
  voltage = data3.registers[0]
  print ("Voltage (V): " , voltage)
  data4 = client.read_holding_registers(13, 1, unit=appid)
  current = data4.registers[0]
  print ("Current (A): " , current)
  data5 = client.read_holding_registers(14, 1, unit=appid)
  activep = data5.registers[0]
  print ("Active Power (kW): " , activep)
  data6 = client.read_holding_registers(15, 1, unit=appid)
  reactivep = data6.registers[0]
  print ("Reactive Power (kvar): " , reactivep)
  data7 = client.read_holding_registers(16, 1, unit=appid)
  freq = data7.registers[0]
  print ("Frequency (Hz): " , freq)
  client.close()
  print ("----------")
  time.sleep(5)
