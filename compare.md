# Compare

~~~ markdown-script
include 'powerwall.mds'

powerwallScenario = powerwallLoadScenario('scenarios-powerwall/seattle-03.json')
vehicleScenario = powerwallValidateVehicleScenario(fetch('scenarios-vehicle/daily-commute.json'))

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
chartHeight = 320

dataLineChart(dataTespoDisabled, objectNew( \
    'title', 'Simulation without TESPO', \
    'width', chartWidth, \
    'height', chartHeight, \
    'x', powerwallFieldDate, \
    'y', arrayNew(powerwallFieldBatteryPercent, 'Vehicle ID-1 Battery (%)', 'Vehicle ID-1 Charging Limit (%)'), \
    'yTicks', objectNew('start', 0, 'end', 100) \
))

dataLineChart(dataTespoEnabled, objectNew( \
    'title', 'Simulation with TESPO', \
    'width', chartWidth, \
    'height', chartHeight, \
    'x', powerwallFieldDate, \
    'y', arrayNew(powerwallFieldBatteryPercent, 'Vehicle ID-1 Battery (%)', 'Vehicle ID-1 Charging Limit (%)'), \
    'yTicks', objectNew('start', 0, 'end', 100) \
))

dataTable(dataTespoEnabled)
~~~
