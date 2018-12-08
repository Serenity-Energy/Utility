
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
port = "COM6"
baudrate = 2400
stopbits = 1
bytesize = 8
parity = "N"
timeout = 1
retries = 2
 
try:
  client = ModbusClient(method = method, port = port, stopbits = stopbits, bytesize = bytesize, parity = parity, baudrate = baudrate, timeout = timeout, retries = retries)
  connection = client.connect()
except:
  print ("Modbus connection error / DDS238")


from flask import Flask, render_template

app = Flask(__name__)

global dds238_total
global dds238_export
global dds238_import
global voltage
global current
global activep
global reactivep
global powfact
global freq
voltage = 0


@app.route("/")
def main():
  appid = 1
  data = client.read_holding_registers(0, 2, unit=appid)
  dds238_kwh_L = data.registers[0]
  dds238_kwh_H = data.registers[1] / 100
  dds238_total = dds238_kwh_L + dds238_kwh_H
  data1 = client.read_holding_registers(8, 2, unit=appid)
  dds238_export_kwh_L = data1.registers[0]
  dds238_export_kwh_H = data1.registers[1] / 100
  dds238_export = dds238_export_kwh_L + dds238_export_kwh_H
  data2 = client.read_holding_registers(10, 2, unit=appid)
  dds238_import_kwh_L = data2.registers[0]
  dds238_import_kwh_H = data2.registers[1] / 100
  dds238_import = dds238_import_kwh_L + dds238_import_kwh_H
  data3 = client.read_holding_registers(12, 1, unit=appid)
  voltage = data3.registers[0] / 10
  data4 = client.read_holding_registers(13, 1, unit=appid)
  current = data4.registers[0] / 100
  data5 = client.read_holding_registers(14, 1, unit=appid)
  activep = data5.registers[0] / 1000
  data6 = client.read_holding_registers(15, 1, unit=appid)
  reactivep = data6.registers[0] / 1000
  data65 = client.read_holding_registers(16, 1, unit=appid)
  powfact = data65.registers[0] 
  data7 = client.read_holding_registers(17, 1, unit=appid)
  freq = data7.registers[0] / 100
  return render_template("index.html" , current=current, activep=activep, frequency=freq, voltage=voltage, totalk=dds238_total, importk=dds238_import, exportk=dds238_export)
	


import os
documentpp = 'C:/Users/Ahmad Ashfaq/Desktop/ethtest/buy.html'
document = open(os.path.abspath(documentpp))
	
@app.route("/", methods=['POST'])
def updatevalues():
  appid = 1
  data = client.read_holding_registers(0, 2, unit=appid)
  dds238_kwh_L = data.registers[0]
  dds238_kwh_H = data.registers[1] / 100
  dds238_total = dds238_kwh_L + dds238_kwh_H
  print ("Total kWh: " , dds238_total)
  data1 = client.read_holding_registers(8, 2, unit=appid)
  dds238_export_kwh_L = data1.registers[0]
  dds238_export_kwh_H = data1.registers[1] / 100
  dds238_export = dds238_export_kwh_L + dds238_export_kwh_H
  print ("Export kWh: " , dds238_export)
  data2 = client.read_holding_registers(10, 2, unit=appid)
  dds238_import_kwh_L = data2.registers[0]
  dds238_import_kwh_H = data2.registers[1] / 100
  dds238_import = dds238_import_kwh_L + dds238_import_kwh_H
  print ("Import kWh: " , dds238_import)
  data3 = client.read_holding_registers(12, 1, unit=appid)
  voltage = data3.registers[0] / 10
  print ("Voltage (V): " , voltage)
  data4 = client.read_holding_registers(13, 1, unit=appid)
  current = data4.registers[0] / 100
  print ("Current (A): " , current)
  data5 = client.read_holding_registers(14, 1, unit=appid)
  activep = data5.registers[0] / 1000
  print ("Active Power (kW): " , activep)
  data6 = client.read_holding_registers(15, 1, unit=appid)
  reactivep = data6.registers[0] / 1000
  print ("Reactive Power (kvar): " , reactivep)
  data65 = client.read_holding_registers(16, 1, unit=appid)
  powfact = data65.registers[0]
  print ("Power Factor : " , powfact / 1000) 
  data7 = client.read_holding_registers(17, 1, unit=appid)
  freq = data7.registers[0] / 100
  print ("Frequency (Hz): " , freq)
  print ("----------")
  return render_template('index.html', current=current, activep=activep, frequency=freq, voltage=voltage, totalk=dds238_total, importk=dds238_import, exportk=dds238_export)
  time.sleep(15)  
	

if __name__ == "__main__":
    app.run()

