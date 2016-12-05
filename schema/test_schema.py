#!/bin/env python
# see https://github.com/bernardpaulus/bash_unittest.git

import subprocess
import unittest
import os.path
import sys
import re

class BashFunctionCaller(object):
    '''utilitary class to show some cool magic you can do in python'''
    def __init__(self, script):
        self.script = script

    def __getattr__(self, name):
        '''allows to do caller.FUNC_NAME(ARGS)'''
        def call_fun(*args):
            script_path = "'{}'".format(os.path.join(os.path.dirname(__file__), self.script))
            return subprocess.check_output(
                    ['bash', '-c', 'source {} && {} {}'.format(script_path, name, " ".join(args))],
                    universal_newlines=True)

        return call_fun

def create_tests(suite,arguments):
    lines = open(os.path.join(os.path.dirname(__file__),schemash_path), 'r').readlines()
    regexp = re.compile("function (((?!_out).)*)\(\)")
    tests = [m.group(1) for m in [regexp.search(l) for l in lines] if m is not None]

    defpat="""
def %s(self):
    output = self.script.%s(*self.myExtraArg)
    self.assertEqual(self.script.%s(),output)
"""

    for t in tests:
        tname = "test_" + t
        tout = t + "_out"
        exec(defpat % (tname, t, tout))
        setattr(SchemaTest,tname, eval(tname))
        suite.addTest(SchemaTest(tname, arguments))

class SchemaTest(unittest.TestCase):
    def __init__(self, testName, extraArg):
        super(SchemaTest, self).__init__(testName)
        self.myExtraArg = extraArg

    def setUp(self):
        self.script = BashFunctionCaller(schemash_path)

schemash_path = "schema.sh"
clientIP = sys.argv.pop()
serverIP = sys.argv.pop()
containerName = sys.argv.pop()
arguments = [serverIP, clientIP, containerName]
# call your test
suite = unittest.TestSuite()
create_tests(suite,arguments)
unittest.TextTestRunner(verbosity=2).run(suite)
