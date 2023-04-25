# TESPO Simulation Scenarios

~~~ markdown-script
include 'powerwall.mds'


# Run each powerwall scenario with each vehicle scenario
scenarioData = arrayNew()
foreach powerwallScenarioURL in fetch('scenarios/powerwallScenarioURLs.json') do
    foreach vehicleScenarioURL in fetch('scenarios/vehicleScenarios.json') do
        # Load each scenario
        powerwallScenario = powerwallLoadScenario(powerwallScenarioURL)
        batteryPercent = powerwallBatteryPercent(powerwallScenario)
        vehicleScenario = powerwallValidateVehicleScenario(fetch(vehicleScenarioURL))

        # Run the scenario simulation without TESPO
        vehicleScenarioCopy = jsonParse(jsonStringify(vehicleScenario))
        dataNoTespo = powerwallSimulate(powerwallScenario, batteryPercent, vehicleScenarioCopy, false)

        # Run the scenario simulation with TESPO
        vehicleScenarioCopy = jsonParse(jsonStringify(vehicleScenario))
        dataTespo = powerwallSimulate(powerwallScenario, batteryPercent, vehicleScenarioCopy, true)

        # Add the powerwall and grid to/from fields
        aggDatum = arrayNew()
        foreach data in arrayNew(dataNoTespo, dataTespo) do
            dataCalculatedField( \
                data, \
                'To Powerwall (kW)', \
                'if([' + powerwallFieldPowerwall + '] < 0, [' + powerwallFieldPowerwall + '], 0)'  \
            )
            dataCalculatedField( \
                data, \
                'From Powerwall (kW)', \
                'if([' + powerwallFieldPowerwall + '] > 0, [' + powerwallFieldPowerwall + '], 0)' \
            )
            dataCalculatedField( \
                data, \
                'To Grid (kW)', \
                'if([' + powerwallFieldGrid + '] < 0, [' + powerwallFieldGrid + '], 0)' \
            )
            dataCalculatedField( \
                data, \
                'From Grid (kW)', \
                'if([' + powerwallFieldGrid + '] > 0, [' + powerwallFieldGrid + '], 0)' \
            )

            # Aggregate the data
            aggData = dataAggregate(data, objectNew( \
                'measures', arrayNew( \
                    objectNew('field', 'Home (kW)', 'function', 'sum'), \
                    objectNew('field', 'Solar Energy (kW)', 'function', 'sum'), \
                    objectNew('field', 'To Powerwall (kW)', 'function', 'sum'), \
                    objectNew('field', 'From Powerwall (kW)', 'function', 'sum'), \
                    objectNew('field', 'From Grid (kW)', 'function', 'sum'), \
                    objectNew('field', 'To Grid (kW)', 'function', 'sum') \
                ) \
            ))
            arrayPush(aggDatum, aggData)

            # Compute self-powered percentage
            dataCalculatedField( \
                aggData, \
                'Self-Powered (%)', \
                '100 * ([' + powerwallFieldHome + '] - [From Grid (kW)]) / [' + powerwallFieldHome + ']' \
            )
        endforeach
        aggDataNoTespo = arrayGet(aggDatum, 0)
        aggDataTespo = arrayGet(aggDatum, 1)
        aggRowNoTespo = arrayGet(aggDataNoTespo, 0)
        aggRowTespo = arrayGet(aggDataTespo, 0)

        # Add the scenario table row
        powerwallScenarioName = objectGet(powerwallScenario, 'name')
        vehicleScenarioName = objectGet(vehicleScenario, 'name')
        noTespoSelfPowered = objectGet(aggRowNoTespo, 'Self-Powered (%)')
        tespoSelfPowered = objectGet(aggRowTespo, 'Self-Powered (%)')
        noTespoFromGrid = objectGet(aggRowNoTespo, 'From Grid (kW)')
        tespoFromGrid = objectGet(aggRowTespo, 'From Grid (kW)')
        noTespoToGrid = objectGet(aggRowNoTespo, 'To Grid (kW)')
        tespoToGrid = objectGet(aggRowTespo, 'To Grid (kW)')
        scenarioRow = objectNew( \
            'Powerwall Scenario', '[' + markdownEscape(powerwallScenarioName) + ', ' + markdownEscape(vehicleScenarioName) + \
                '](#url=compare.md&' + \
                "var.vPowerwallScenario='" + encodeURIComponent(powerwallScenarioURL) + "'&" + \
                "var.vVehicleScenario='" + encodeURIComponent(vehicleScenarioURL) + "'" + \
                ')', \
            'Self-Powered Difference (%)', 100 * (tespoSelfPowered - noTespoSelfPowered) / noTespoSelfPowered, \
            'From Grid Difference (%)', if(noTespoFromGrid != 0, 100 * (tespoFromGrid - noTespoFromGrid) / noTespoFromGrid, 0), \
            'To Grid Difference (%)', if(noTespoToGrid != 0, 100 * (tespoToGrid - noTespoToGrid) / noTespoToGrid, 0) \
        )
        arrayPush(scenarioData, scenarioRow)
    endforeach
endforeach

# Render the scenario table
dataTable(scenarioData, objectNew( \
    'markdown', arrayNew('Powerwall Scenario') \
))
~~~
