# Compare

~~~ markdown-script
include 'powerwall.mds'

powerwallScenario = powerwallLoadScenario(vPowerwallScenario)
initialBatteryPercent = powerwallBatteryPercent(powerwallScenario)
vehicleScenario = fetch(vVehicleScenario)

vehicleScenarioCopy = jsonParse(jsonStringify(vehicleScenario))
dataTespoDisabled = powerwallSimulate( \
    powerwallScenario, \
    initialBatteryPercent, \
    vehicleScenarioCopy, \
    0 \
)

vehicleScenarioCopy = jsonParse(jsonStringify(vehicleScenario))
dataTespoEnabled = powerwallSimulate( \
    powerwallScenario, \
    initialBatteryPercent, \
    vehicleScenarioCopy, \
    2 \
)

chartWidth = 1200
chartHeight = 300

markdownPrint( \
    '**Powerwall Scenario:** ' + markdownEscape(objectGet(powerwallScenario, 'name')) + ' \\', \
    '**Vehicle Scenario:** ' + markdownEscape(objectGet(vehicleScenario, 'name')) \
)

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

dataTable(dataTespoEnabled, objectNew( \
    'fields', arrayNew( \
        powerwallFieldDate, \
        powerwallFieldHome, \
        powerwallFieldSolar, \
        powerwallFieldGrid, \
        powerwallFieldPowerwall, \
        powerwallFieldBatteryPercent, \
        powerwallFieldBackupPercent, \
        'Vehicle ID-1 Connected', \
        'Vehicle ID-1 (kWh)', \
        'Vehicle ID-1 Battery (%)', \
        'Vehicle ID-1 Charging Rate (amps)', \
        'Vehicle ID-1 Charging Limit (%)' \
    ) \
))
~~~
