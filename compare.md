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

dataTable(dataTespoEnabled)
~~~
