#!/bin/env python
# see https://github.com/bernardpaulus/bash_unittest.git

import subprocess
import unittest
import os.path
import sys

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

class SchemaTest(unittest.TestCase):
    def __init__(self, testName, extraArg):
        super(SchemaTest, self).__init__(testName)
        self.myExtraArg = extraArg

    def setUp(self):
        self.script = BashFunctionCaller("../schema/schema.sh")

    def test_modify(self):
        output = self.script.modify(self.myExtraArg)
        self.assertEqual(self.script.modify_out(), output)

    def test_login(self):
        output = self.script.login(self.myExtraArg)
        self.assertEqual(self.script.login_out(), output)

    def test_password(self):
        output = self.script.password(self.myExtraArg)
        self.assertEqual(self.script.password_out(), output)

    def test_ssh(self):
        output = self.script.ssh(self.myExtraArg)
        self.assertEqual(self.script.ssh_out(), output)

    def test_struct(self):
        output = self.script.struct(self.myExtraArg)
        self.assertEqual(self.script.struct_out(), output[0:92] + "\n")

    def test_structuralObjectClass(self):
        output = self.script.structuralObjectClass(self.myExtraArg)
        self.assertEqual(self.script.structuralObjectClass_out(), output)

    def test_anonymous(self):
        output = self.script.anonymous(self.myExtraArg)
        self.assertEqual(self.script.anonymous_out(), output)

# call your test
clientIP = sys.argv.pop()
serverIP = sys.argv.pop()
suite = unittest.TestSuite()
suite.addTest(SchemaTest('test_password',serverIP))
suite.addTest(SchemaTest('test_modify',serverIP))
suite.addTest(SchemaTest('test_login',serverIP))
suite.addTest(SchemaTest('test_ssh',clientIP))
suite.addTest(SchemaTest('test_struct',serverIP))
suite.addTest(SchemaTest('test_structuralObjectClass',serverIP))
suite.addTest(SchemaTest('test_anonymous',serverIP))
unittest.TextTestRunner(verbosity=2).run(suite)
