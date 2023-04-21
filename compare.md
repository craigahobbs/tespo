# Compare

~~~ markdown-script
include 'powerwall.mds'

powerwallScenario = powerwallLoadScenario(vPowerwallScenario)
vehicleScenario = fetch(vVehicleScenario)

markdownPrint( \
    '**Powerwall Scenario:** ' + markdownEscape(objectGet(powerwallScenario, 'name')) + ' \\', \
    '**Vehicle Scenario:** ' + markdownEscape(objectGet(vehicleScenario, 'name')) \
)

dataTespoDisabled = powerwallSimulate( \
    powerwallScenario, \
    powerwallBatteryPercent(powerwallScenario), \
    vehicleScenario, \
    false \
)

dataTespoEnabled = powerwallSimulate( \
    powerwallScenario, \
    powerwallBatteryPercent(powerwallScenario), \
    vehicleScenario, \
    true \
)

chartWidth = 1200
chartHeight = 300

dataLineChart(dataTespoDisabled, objectNew( \
    'title', 'Simulation without TESPO', \
    'width', chartWidth, \
    'height', chartHeight, \
    'x', powerwallFieldDate, \
    'y', arrayNew(powerwallFieldBatteryPercent, powerwallFieldBackupPercent, 'Vehicle ID-1 Battery (%)', 'Vehicle ID-1 Charging Limit (%)'), \
    'yTicks', objectNew('start', 0, 'end', 100) \
))

dataLineChart(dataTespoEnabled, objectNew( \
    'title', 'Simulation with TESPO', \
    'width', chartWidth, \
    'height', chartHeight, \
    'x', powerwallFieldDate, \
    'y', arrayNew(powerwallFieldBatteryPercent, powerwallFieldBackupPercent, 'Vehicle ID-1 Battery (%)', 'Vehicle ID-1 Charging Limit (%)'), \
    'yTicks', objectNew('start', 0, 'end', 100) \
))

dataTable(dataTespoEnabled)
~~~
