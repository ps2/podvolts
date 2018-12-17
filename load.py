# -*- coding: utf-8 -*-
"""Tutorial how to use the class helper `SeriesHelper`."""

from influxdb import InfluxDBClient
from influxdb import SeriesHelper
import csv,sys,time,pytz
from datetime import datetime,timedelta
import re

# InfluxDB connections settings
host = 'localhost'
port = 8086
user = 'root'
password = 'root'
dbname = 'podvolts'

myclient = InfluxDBClient(host, port, user, password, dbname)

class VoltSeriesHelper(SeriesHelper):
    """Instantiate SeriesHelper to write points to the backend."""

    class Meta:
        """Meta class stores time series helper configuration."""

        # The client should be an instance of InfluxDBClient.
        client = myclient

        # The series name must be a string. Add dependent fields/tags
        # in curly brackets.
        series_name = 'podvolts'

        # Defines all the fields in this time series.
        fields = ['volts_c2', 'volts_c3']

        # Defines all the tags for the series.
        tags = ['pod_id']

        # Defines the number of data points to store prior to writing
        # on the wire.
        bulk_size = 10000

        # autocommit must be set to True when using bulk_size
        autocommit = True



voltage_scale = 993 / 4.788

def load(filename, pod_id):
    # Expecting: 2018121523.csv
    m = re.search(r'(\d\d\d\d)(\d\d)(\d\d)(\d\d)', filename)
    if not m:
        print("Error, Expected filename in the form '2018121523.csv'")
        exit(-1)


    date = datetime(int(m[1]), int(m[2]), int(m[3]), int(m[4])).astimezone(pytz.utc)

    print("Loading %s for hour: %s" % (filename, date))

    with open(filename) as csvfile:
        data_reader = csv.reader(csvfile)
        for row in data_reader:
            (minutes,seconds) = row[0].split(":")
            timestamp = date + timedelta(minutes=int(minutes), seconds=float(seconds))
            volts_c2 = int(row[1]) / voltage_scale
            volts_c3 = int(row[2]) / voltage_scale
            VoltSeriesHelper(pod_id=pod_id, volts_c2=volts_c2, volts_c3=volts_c3, time=timestamp)
 
    VoltSeriesHelper.commit()
    # To inspect the JSON which will be written, call _json_body_():
    #VoltSeriesHelper._json_body_()

def usage():
    print('load.py filename.csv pod_id')

def main(argv):
    if len(argv) != 2:
        usage()
        exit(-1)
    load(argv[0], argv[1])

if __name__ == "__main__":
    main(sys.argv[1:])
