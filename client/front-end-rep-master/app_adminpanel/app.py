from __future__ import division

import time
from flask import Flask, render_template

app = Flask(__name__)

@app.route("/")
def main():
  return render_template("index.html", gridCap=0.0, batCap=0.0)
		
@app.route('/demand')
def demandfunction(): 
  return render_template('demand.html')

@app.route('/increase')
def increasefunction(): 
  return render_template('increase.html')

@app.route('/registeruser')
def registeruserfunction(): 
  return render_template('registeruser.html')

@app.route('/update')
def updatefunction(): 
  return render_template('update.html')

if __name__ == "__main__":
    app.run()
