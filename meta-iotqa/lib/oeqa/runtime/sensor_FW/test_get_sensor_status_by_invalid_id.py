'''negatively verify api sf_get_sensor_status_by_id'''
import os
import readConfigFile
from oeqa.oetest import oeRuntimeTest

class TestGetSensorStatusByInvalidId(oeRuntimeTest):
    '''Verify error returns from sf_get_sensor_status if id is invalid'''
    def test(self):
        '''push binary to target and run with argument'''
        mkdir_path = "mkdir -p /opt/sensor-test/apps"
        (status, output) = self.target.run(mkdir_path)
        copy_to_path = os.path.join(get_files_dir(), 'test_get_sensor_status_by_id')
        (status, output) = self.target.copy_to(copy_to_path,\
"/opt/sensor-test/apps/")
        #run test get sensor status by invalid id and show it's information
        client_cmd = "/opt/sensor-test/apps/test_get_sensor_status_by_id "\
                     + readConfigFile.ReadConfFile.getSectionValue( 'sensors','invalid-id')
        (status, output) = self.target.run(client_cmd)
        print output
        self.assertEqual(status, 2, msg="Error messages: %s" % output)
