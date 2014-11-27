"""
"""

import datetime
import httplib2
import http
import argparse
import configparser
import sys
import os
import time

cur_path = os.path.realpath('')
app_version = 1.0


class UrlParser:
    """
    """

    def __init__(self):
        """
        Intializing parameters
        """
        pass

    def readcontent(self, input_file):
        """
        Read the file and return the content in dictionary format
        :param input_file : command line parameter ini/cfg file
        """
        config_file = configparser.RawConfigParser()
        config_file.read(input_file)
        file_input = {}
        no_test_cases = config_file.sections()
        for option in no_test_cases:
            input_option = {}
            for items in config_file.items(option):
                input_option[items[0]] = items[1]
            file_input[option] = input_option
        try:
            input_properties = file_input['initproperties']
        except KeyError:
            print("There is no init properites input in the file")
            sys.exit()
        del file_input['initproperties']
        return file_input, input_properties

    def get_file_name(self, filename):
        """
        Return the file name
		:param filename: file name get from the parameter file
        """
        file = str(datetime.datetime.now().strftime("%Y%m%d%H%M%S"))
        #all_list = [file, filename, '.txt']
        return str(file+ '_' + filename)

    def getpostrequest(self, params, input_properties):
        """
        Get the url and content and parse it and get the response and display
        :param params: 
        :param input_properties: input and output location , debug position
        """
        #try:
        for section in params.keys():
            print("try connect %s" % params[section])
            conn = http.client.HTTPConnection(params[section]['url'])
            print("Connected to url")
            if params[section]['content_file'] and params[section]['content']:
                print("Both options was given by default we are taking file")
            if params[section]['content_file']:
                #get all values from the furrent file and slplit to list
                temp_list = params[section]['content_file'].split(',')
                file_list =[]
                #make it list of list like [[filename, 2],[finename 3]]
                for val in temp_list:
                    file_list.append(val.strip().split(' '))
                for temp in file_list:
                    if len(temp) ==1:
                        temp.append('1')
                for temp_val in file_list:
                    try:
                        if input_properties['input_dir']:
                            input_file = ''.join([input_properties['input_dir'], temp_val[0]])
                        else:
                            input_file = ''.join([cur_path, '//input//', temp_val[0]])
                    except KeyError:
                        print("input dir parameter is not exit")
                        sys.exit()                        
                    #import pdb;pdb.set_trace()
                    f = open(input_file, 'r')
                    content = f.read()
                    for val in range(0, int(temp_val[1])):
                        time.sleep(1)  # delay for one sec
                        conn.request(params[section]['method'], "/"+params[section]['page'], content)
                        self.response_data(section, conn, params, input_properties)
                    f.close()
            else:
                conn.request(params[section]['method'], "/"+params[section]['page'], params[section]['content'])
                self.response_data(section, conn, params)
        #except :
        #    print("Connection was not etablished")
        #    sys.exit()

    def response_data(self, section, conn, params, input_properties):
        """
        Response data is writing in console or file according to parameretization

        :param section : 
        :param conn: url connection
        :param params : 
        :param input_properties:
        """
        print("Sent the request to url")
        response = conn.getresponse()
        print("Got the response")
        if params[section]['result_file']:
            temp_list = params[section]['content_file'].split(',')
            file_list =[]
            #make it list of list like [[filename, 2],[finename 3]]
            for val in temp_list:
                file_list.append(val.strip().split(' '))
            file_name = self.get_file_name(file_list[0][0])
            try:
                if input_properties['output_dir']:
                    fl = open(input_properties['output_dir']+ "/" + file_name + '.txt', 'w')
                else:
                    fl = open(cur_path + "/output/" + file_name + '.txt', 'w')
            except:
                print("output dir parameter is not exit")
                sys.exit()
            fl.write(str(response.read()))
            fl.close()
        if params[section]['result_console']:
            print(response.read())


if __name__ == "__main__":
    print("coffee script auto testing suite ver %s" % app_version)
    argument1 = sys.argv[1]
    print(argument1)
    parser_obj = UrlParser()
    params, input_properties = parser_obj.readcontent(argument1)
    print("test cases input in the format of dictionaries")
    print(params)
    print("init parameters in the format of dictionaries")
    print(input_properties)
    #import pdb;pdb.set_trace()
    parser_obj.getpostrequest(params, input_properties)
    print("End the process")
