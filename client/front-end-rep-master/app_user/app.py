
from __future__ import division
import pymodbus
import serial
import time
import decimal
from pymodbus.pdu import ModbusRequest
from pymodbus.client.sync import ModbusSerialClient as ModbusClient #initialize a serial RTU client instance
from pymodbus.transaction import ModbusRtuFramer
 
from pymodbus.constants import Endian              # Needed for 32-bit float numbers (2 registers / 4 bytes)
from pymodbus.payload import BinaryPayloadDecoder  # Required for 32-bit float numbers (2 registers / 4 bytes)
from pymodbus.payload import BinaryPayloadBuilder  # Need to write 32-bit drivers to register
 

# Initialising energy meter variables for modbus client

method = "rtu"
port = "/dev/ttyUSB0"
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


from flask import Flask, render_template, request

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
global ergon
global hashaddress
global vwallet


tb = 0  # Total balance of the user
voltage = 0 
fetchme = 0 # New topup received from smart contract
repeat = 0  # For updating total balance

# Getting values from energy meter on modbus client and setting initial reading of energy meter
appid = 1
initial_data = client.read_holding_registers(0, 2, unit=appid)
initial_dds238_kwh_L = initial_data.registers[0]
initial_dds238_kwh_H = initial_data.registers[1] / 100
initial_reading = initial_dds238_kwh_L + initial_dds238_kwh_H


@app.route("/")
def main(): 
  return render_template('start.html')

@app.route("/home", methods = ['POST', 'GET'])
def start():
  global tb
  global fetchme
  global repeat
  global initial_reading
  
  # Updates total balance of user when received from admin panel
  if request.method == 'POST':
    fetchme = request.form['fetch']
    repeat = request.form['complete']
    tb = tb + float(fetchme)   
    
   
  # Getting values from energy meter on modbus client
  appid = 1
  data = client.read_holding_registers(0, 2, unit=appid)
  dds238_kwh_L = data.registers[0]
  dds238_kwh_H = data.registers[1] / 100
  dds238_total = dds238_kwh_L + dds238_kwh_H
  
  
  # Decreases total balance as more energy is consumed
  if dds238_total > initial_reading and tb > 0:
    tb = tb - (dds238_total - initial_reading)
    initial_reading = dds238_total
  

  # Getting values from energy meter on modbus client
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
  return render_template("index.html" , total_b=tb, repeat=repeat, current=current, activep=activep, frequency=freq, voltage=voltage, totalk=dds238_total, importk=dds238_import, exportk=dds238_export)

	
@app.route('/buy', methods = ['POST', 'GET'])
def buy():
  global tb
  global fetchme
  global repeat
  global initial_reading

  # Updates total balance of user when received from admin panel
  if request.method == 'POST':
    fetchme = request.form['fetch']
    repeat = request.form['complete']
    tb = tb + float(fetchme)

  # Getting values from energy meter on modbus client
  appid = 1
  data = client.read_holding_registers(0, 2, unit=appid)
  dds238_kwh_L = data.registers[0]
  dds238_kwh_H = data.registers[1] / 100
  dds238_total = dds238_kwh_L + dds238_kwh_H
  
  # Decreases total balance as more energy is consumed
  if dds238_total > initial_reading and tb > 0:
    tb = tb - (dds238_total - initial_reading)
    initial_reading = dds238_total

  return render_template('buy.html' , total_b=tb, repeat=repeat)

@app.route('/sell', methods = ['POST', 'GET'])
def sell():
  global tb
  global fetchme
  global repeat
  global initial_reading

  # Updates total balance of user when received from admin panel
  if request.method == 'POST':
    fetchme = request.form['fetch']
    repeat = request.form['complete']
    tb = tb + float(fetchme)

  # Getting values from energy meter on modbus client
  appid = 1
  data = client.read_holding_registers(0, 2, unit=appid)
  dds238_kwh_L = data.registers[0]
  dds238_kwh_H = data.registers[1] / 100
  dds238_total = dds238_kwh_L + dds238_kwh_H
  
  # Decreases total balance as more energy is consumed
  if dds238_total > initial_reading and tb > 0:
    tb = tb - (dds238_total - initial_reading)
    initial_reading = dds238_total


  return render_template('sell.html' , total_b=tb, repeat=repeat)

@app.route('/wallet')
def wallet():
  global tb
  global initial_reading

  # Getting values from energy meter on modbus client
  appid = 1
  data = client.read_holding_registers(0, 2, unit=appid)
  dds238_kwh_L = data.registers[0]
  dds238_kwh_H = data.registers[1] / 100
  dds238_total = dds238_kwh_L + dds238_kwh_H
  
  # Decreases total balance as more energy is consumed
  if dds238_total > initial_reading and tb > 0:
    tb = tb - (dds238_total - initial_reading)
    initial_reading = dds238_total

  return render_template('wallet.html')

@app.route('/support')
def support(): 
  global tb
  global initial_reading

  # Getting values from energy meter on modbus client
  appid = 1
  data = client.read_holding_registers(0, 2, unit=appid)
  dds238_kwh_L = data.registers[0]
  dds238_kwh_H = data.registers[1] / 100
  dds238_total = dds238_kwh_L + dds238_kwh_H
  
  # Decreases total balance as more energy is consumed
  if dds238_total > initial_reading and tb > 0:
    tb = tb - (dds238_total - initial_reading)
    initial_reading = dds238_total

  return render_template('support.html')

if __name__ == "__main__":
    app.run()

