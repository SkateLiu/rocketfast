"""
Simple iOS tests, showing accessing elements and getting/setting text from them.
"""
import unittest
import os
from random import randint
from appium import webdriver
from time import sleep

class SimpleIOSTests(unittest.TestCase):

    def setUp(self):
        # set up appium
        app = os.path.abspath('./Rocket/RocketFast.ipa')
        self.driver = webdriver.Remote(
            command_executor='http://127.0.0.1:4723/wd/hub',
            desired_capabilities={
                'app': app,
                'platformName': 'iOS',
                'platformVersion': '13.1',
                'deviceName': 'Teemo iPhone',
                'udid': '00008020-000D55521E38002E',
                'automationName': 'XCUITest'
            })

    def tearDown(self):
        self.driver.quit()

    def test_ui_computation(self):
        element = self.driver.find_element_by_accessibility_id('username')
        element.send_keys('dingdone')
        passwordElement = self.driver.find_element_by_accessibility_id('password')
        passwordElement.send_keys('123456')
        loginElement = self.driver.find_element_by_accessibility_id('login')
        loginElement.click()


if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(SimpleIOSTests)
    unittest.TextTestRunner(verbosity=2).run(suite)