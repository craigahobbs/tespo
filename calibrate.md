~~~ markdown-script
# Licensed under the MIT License
# https://github.com/craigahobbs/tespo/blob/main/LICENSE

include 'powerwall.mds'


async function calibrateMain()
    # Render the selected scenario, if requested
    if vScenarioURL != null then
        calibrateDetail()
        return
    endif

    # Render the scenario index
    calibrateIndex()
endfunction


async function calibrateIndex()
    # Set the title
    title = 'TESPO Powerwall Scenario Calibration'
    setDocumentTitle(title)
    markdownPrint('[Home](#url=&var=)', '', '# ' + markdownEscape(title))

    # Fetch the scenario files
    scenarioJSONs = fetch(scenarioURLs)

    # Create the scenario data table
    scenarioTable = arrayNew()
    foreach scenarioJSON, ixScenario in scenarioJSONs do
        scenarioName = objectGet(scenarioJSON, 'name')
        arrayPush(scenarioTable, objectNew( \
            'Scenario', '[' + markdownEscape(scenarioName) + "](#var.vScenarioURL='" + arrayGet(scenarioURLs, ixScenario) + "')", \
            'Battery Capacity (kWh)', objectGet(scenarioJSON, 'batteryCapacity'), \
            'Backup (%)', objectGet(scenarioJSON, 'backupPercent'), \
            'Charge Ratio', objectGet(scenarioJSON, 'chargeRatio'), \
            'Discharge Ratio', objectGet(scenarioJSON, 'dischargeRatio') \
        ))
    endforeach

    # Render the scenario table
    dataTable(scenarioTable, objectNew( \
        'markdown', arrayNew('Scenario') \
    ))
endfunction


async function calibrateDetail()
    # Set the default title
    title = 'TESPO Simulation Scenario Calibration'
    setDocumentTitle(title)

    # Load the scenario
    scenario = if(vScenarioURL != null, powerwallLoadScenario(vScenarioURL))
    if scenario == null then
        markdownPrint( \
            'Failed to load scenario URL "' + vScenarioURL + '".', \
            '', \
            "Check the `var.vScenarioURL='scenario.json'` hash parameter." \
        )
        return
    endif
    data = objectGet(scenario, 'data')
    scenarioName = objectGet(scenario, 'name')

    # Variable scenario overrides
    batteryCapacity = if(vBatteryCapacity, mathMax(1, vBatteryCapacity), objectGet(scenario, 'batteryCapacity'))
    backupPercent = if(vBackupPercent, mathMax(0, vBackupPercent), objectGet(scenario, 'backupPercent'))
    chargeRatio = if(vChargeRatio, mathMax(0.1, vChargeRatio), objectGet(scenario, 'chargeRatio'))
    dischargeRatio = if(vDischargeRatio, mathMax(0.1, vDischargeRatio), objectGet(scenario, 'dischargeRatio'))
    precision = if(vPrecision, mathMax(1, mathRound(vPrecision)), calibrateDefaultPrecision)
    ratioDelta = 0.1 ** precision

    # Simulate the scenario
    objectSet(scenario, 'batteryCapacity', batteryCapacity)
    objectSet(scenario, 'backupPercent', backupPercent)
    objectSet(scenario, 'chargeRatio', chargeRatio)
    objectSet(scenario, 'dischargeRatio', dischargeRatio)
    simulated = powerwallSimulate(scenario, powerwallBatteryPercent(scenario))

    # Compute the differences
    differences = arrayNew()
    powerwallManhattanSum = 0
    gridManhattanSum = 0
    batteryManhattanSum = 0
    powerwallEuclidianSum = 0
    gridEuclidianSum = 0
    batteryEuclidianSum = 0
    foreach row, ixRow in data do
        rowSimulated = arrayGet(simulated, ixRow)

        # Compute the diffs
        powerwallDiff = objectGet(rowSimulated, powerwallFieldPowerwall) - objectGet(row, powerwallFieldPowerwall)
        gridDiff = objectGet(rowSimulated, powerwallFieldGrid) - objectGet(row, powerwallFieldGrid)
        batteryDiff = objectGet(rowSimulated, powerwallFieldBatteryPercent) - objectGet(row, powerwallFieldBatteryPercent)

        # Update the Manhattan distance sums
        powerwallManhattanSum = powerwallManhattanSum + mathAbs(powerwallDiff)
        gridManhattanSum = gridManhattanSum + mathAbs(gridDiff)
        batteryManhattanSum = batteryManhattanSum + mathAbs(batteryDiff)

        # Update the Euclidian distance sums
        powerwallEuclidianSum = powerwallEuclidianSum + powerwallDiff * powerwallDiff
        gridEuclidianSum = gridEuclidianSum + gridDiff * gridDiff
        batteryEuclidianSum = batteryEuclidianSum + batteryDiff * batteryDiff

        # Add the differences data row
        arrayPush(differences, objectNew( \
            powerwallFieldDate, objectGet(row, powerwallFieldDate), \
            powerwallFieldPowerwall, powerwallDiff, \
            powerwallFieldGrid, gridDiff, \
            powerwallFieldBatteryPercent, batteryDiff \
        ))
    endforeach

    # Compute the Manhattan distances
    powerwallManhattanDistance = powerwallManhattanSum / arrayLength(data)
    gridManhattanDistance = gridManhattanSum / arrayLength(data)
    batteryManhattanDistance = batteryManhattanSum / arrayLength(data)

    # Compute the Euclidian distances
    powerwallEuclidianDistance = mathSqrt(powerwallEuclidianSum)
    gridEuclidianDistance = mathSqrt(gridEuclidianSum)
    batteryEuclidianDistance = mathSqrt(batteryEuclidianSum)

    # Chart constants
    chartWidth = 1250
    chartHeight = 250
    fontSize = getDocumentFontSize()

    # Controls
    setDocumentTitle(scenarioName)
    markdownPrint( \
        '[Back](#var=)', \
        '', \
        '# ' + title, \
        '', \
        '**Scenario:** ' + markdownEscape(scenarioName), \
        '', \
        '**Battery Capacity:** ' + numberToFixed(batteryCapacity, 1) + '&nbsp;&nbsp;', \
        '[Up](' + calibrateURL(objectNew('batteryCapacity', mathMin(batteryCapacity + 0.1, 100)), scenario) + ')', \
        '[Down](' +  calibrateURL(objectNew('batteryCapacity', mathMax(batteryCapacity - 0.1, 1)), scenario) + ') \\', \
        '**Backup Percent:** ' + backupPercent + '&nbsp;&nbsp;', \
        '[Up](' + calibrateURL(objectNew('backupPercent', mathMin(backupPercent + 1, 100)), scenario) + ')', \
        '[Down](' + calibrateURL(objectNew('backupPercent', mathMax(backupPercent - 1, 0)), scenario) + ') \\', \
        '**Charge Ratio:** ' + numberToFixed(chargeRatio, precision) + '&nbsp;&nbsp;', \
        '[Up](' + calibrateURL(objectNew('chargeRatio', chargeRatio + ratioDelta), scenario) + ')', \
        '[Down](' + calibrateURL(objectNew('chargeRatio', mathMax(chargeRatio - ratioDelta, ratioDelta)), scenario) + ') \\', \
        '**Discharge Ratio:** ' + numberToFixed(dischargeRatio, precision) + '&nbsp;&nbsp;', \
        '[Up](' + calibrateURL(objectNew('dischargeRatio', dischargeRatio + ratioDelta), scenario) + ')', \
        '[Down](' + calibrateURL(objectNew('dischargeRatio', mathMax(dischargeRatio - ratioDelta, ratioDelta)), scenario) + ') \\', \
        '**Precision:** ' + precision + '&nbsp;&nbsp;', \
        '[Up](' + calibrateURL(objectNew('precision', precision + 1), scenario) + ')', \
        '[Down](' + calibrateURL(objectNew('precision', mathMax(precision - 1, 1)), scenario) + ') \\', \
        '[Reset](' + calibrateURL(objectNew('scenarioURL', vScenarioURL), null) + ')', \
        '', \
        '## Error', \
        '', \
        '**Powerwall:**&nbsp;&nbsp;' + numberToFixed(powerwallManhattanDistance, precision), \
        '&nbsp;/&nbsp;' + numberToFixed(powerwallEuclidianDistance, precision) + ' \\', \
        '**Grid:**&nbsp;&nbsp;' + numberToFixed(gridManhattanDistance, precision), \
        '&nbsp;/&nbsp;' + numberToFixed(gridEuclidianDistance, precision) + ' \\', \
        '**Battery:**&nbsp;&nbsp;' + numberToFixed(batteryManhattanDistance, precision), \
        '&nbsp;/&nbsp;' + numberToFixed(batteryEuclidianDistance, precision), \
        '', \
        'Note: Error values reported as Manhattan/Euclidian distance.' \
    )

    # Difference data
    markdownPrint('', '---')
    dataLineChart(differences, objectNew( \
        'title', 'Simulated Powerwall/Grid Difference', \
        'width', chartWidth, \
        'height', chartHeight, \
        'x', powerwallFieldDate, \
        'y', arrayNew(powerwallFieldPowerwall, powerwallFieldGrid), \
        'yTicks', objectNew('count', 2), \
        'yLines', arrayNew(objectNew('value', 0)) \
    ))
    dataLineChart(differences, objectNew( \
        'title', 'Simulated Battery Difference', \
        'width', chartWidth - mathFloor(10 * fontSize), \
        'height', chartHeight, \
        'x', powerwallFieldDate, \
        'y', arrayNew(powerwallFieldBatteryPercent), \
        'yTicks', objectNew('count', 2), \
        'yLines', arrayNew(objectNew('value', 0)) \
    ))

    # Home/Solar data
    markdownPrint('', '---')
    dataLineChart(data, objectNew( \
        'title', 'Home/Solar', \
        'width', chartWidth - mathFloor(2.5 * fontSize), \
        'height', chartHeight, \
        'x', powerwallFieldDate, \
        'y', arrayNew(powerwallFieldHome, powerwallFieldSolar), \
        'yTicks', objectNew('start', 0) \
    ))

    # Powerwall/Grid
    markdownPrint('', '---')
    dataLineChart(data, objectNew( \
        'title', 'Actual Powerwall/Grid', \
        'width', chartWidth, \
        'height', chartHeight, \
        'x', powerwallFieldDate, \
        'y', arrayNew(powerwallFieldPowerwall, powerwallFieldGrid), \
        'yTicks', objectNew('count', 2), \
        'yLines', arrayNew(objectNew('value', 0)) \
    ))
    dataLineChart(simulated, objectNew( \
        'title', 'Simulated Powerwall/Grid', \
        'width', chartWidth, \
        'height', chartHeight, \
        'x', powerwallFieldDate, \
        'y', arrayNew(powerwallFieldPowerwall, powerwallFieldGrid), \
        'yTicks', objectNew('count', 2), \
        'yLines', arrayNew(objectNew('value', 0)) \
    ))

    # Battery
    markdownPrint('', '---')
    dataLineChart(data, objectNew( \
        'title', 'Actual Battery', \
        'width', chartWidth - mathFloor(10 * fontSize), \
        'height', chartHeight, \
        'x', powerwallFieldDate, \
        'y', arrayNew(powerwallFieldBatteryPercent), \
        'yTicks', objectNew('start', 0, 'end', 100), \
        'yLines', arrayNew(objectNew('value', backupPercent)) \
    ))
    dataLineChart(simulated, objectNew( \
        'title', 'Simulated Battery', \
        'width', chartWidth - mathFloor(10 * fontSize), \
        'height', chartHeight, \
        'x', powerwallFieldDate, \
        'y', arrayNew(powerwallFieldBatteryPercent), \
        'yTicks', objectNew('start', 0, 'end', 100), \
        'yLines', arrayNew(objectNew('value', backupPercent)) \
    ))

    # Simulated data table
    return
    foreach row, ixRow in data do
        rowSimulated = arrayGet(simulated, ixRow)
        objectSet(row, 'Simulated ' + powerwallFieldPowerwall, objectGet(rowSimulated, powerwallFieldPowerwall))
        objectSet(row, 'Simulated ' + powerwallFieldGrid, objectGet(rowSimulated, powerwallFieldGrid))
        objectSet(row, 'Simulated ' + powerwallFieldBatteryPercent, objectGet(rowSimulated, powerwallFieldBatteryPercent))
    endforeach
    markdownPrint('', '---')
    dataTable(data, objectNew( \
        'fields', arrayNew( \
            powerwallFieldDate, \
            powerwallFieldHome, \
            powerwallFieldSolar, \
            powerwallFieldPowerwall, \
            powerwallFieldGrid, \
            powerwallFieldBatteryPercent, \
            'Simulated ' + powerwallFieldPowerwall, \
            'Simulated ' + powerwallFieldGrid, \
            'Simulated ' + powerwallFieldBatteryPercent \
        ) \
    ))
endfunction


# Helper to create calibrate application URLs
function calibrateURL(args, scenario)
    if scenario != null then
        # URL arguments
        batteryCapacity = if(!reset && objectHas(args, 'batteryCapacity'), objectGet(args, 'batteryCapacity'), vBatteryCapacity)
        backupPercent = if(!reset && objectHas(args, 'backupPercent'), objectGet(args, 'backupPercent'), vBackupPercent)
        chargeRatio = if(!reset && objectHas(args, 'chargeRatio'), objectGet(args, 'chargeRatio'), vChargeRatio)
        dischargeRatio = if(!reset && objectHas(args, 'dischargeRatio'), objectGet(args, 'dischargeRatio'), vDischargeRatio)
        precision = if(!reset && objectHas(args, 'precision'), objectGet(args, 'precision'), vPrecision)

        # Set defaults from the scenario
        batteryCapacity = if(batteryCapacity != null, batteryCapacity, objectGet(scenario, 'batteryCapacity'))
        backupPercent = if(backupPercent != null, backupPercent, objectGet(scenario, 'backupPercent'))
        chargeRatio = if(chargeRatio != null, chargeRatio, objectGet(scenario, 'chargeRatio'))
        dischargeRatio = if(dischargeRatio != null, dischargeRatio, objectGet(scenario, 'dischargeRatio'))
    endif

    # Create the URL
    parts = arrayNew()
    ratioPrecicion = if(vPrecision != null, vPrecision, calibrateDefaultPrecision)
    arrayPush(parts, "var.vScenarioURL='" + encodeURIComponent(vScenarioURL) + "'")
    if(batteryCapacity != null, arrayPush(parts, 'var.vBatteryCapacity=' + mathRound(batteryCapacity, 1)))
    if(backupPercent != null, arrayPush(parts, 'var.vBackupPercent=' + mathRound(backupPercent, 1)))
    if(chargeRatio != null, arrayPush(parts, 'var.vChargeRatio=' + mathRound(chargeRatio, ratioPrecicion)))
    if(dischargeRatio != null, arrayPush(parts, 'var.vDischargeRatio=' + mathRound(dischargeRatio, ratioPrecicion)))
    if(precision != null, arrayPush(parts, 'var.vPrecision=' + precision))
    return if(arrayLength(parts), '#' + arrayJoin(parts, '&'), '#var=')
endfunction


# Variable argument defaults
calibrateDefaultPrecision = 2


# The list of Powerwall scenario files
scenarioURLs = arrayNew( \
    'scenarios/powerwall/seattle-01.json', \
    'scenarios/powerwall/seattle-02.json', \
    'scenarios/powerwall/seattle-03.json', \
    'scenarios/powerwall/seattle-04.json', \
    'scenarios/powerwall/seattle-05.json', \
    'scenarios/powerwall/seattle-06.json', \
    'scenarios/powerwall/seattle-07.json', \
    'scenarios/powerwall/seattle-08.json', \
    'scenarios/powerwall/seattle-09.json', \
    'scenarios/powerwall/seattle-10.json', \
    'scenarios/powerwall/seattle-11.json', \
    'scenarios/powerwall/seattle-12.json', \
    'scenarios/powerwall/seattle-13.json', \
    'scenarios/powerwall/seattle-14.json', \
    'scenarios/powerwall/seattle-15.json', \
    'scenarios/powerwall/seattle-16.json', \
    'scenarios/powerwall/seattle-17.json', \
    'scenarios/powerwall/seattle-18.json', \
    'scenarios/powerwall/seattle-19.json', \
    'scenarios/powerwall/seattle-20.json', \
    'scenarios/powerwall/seattle-21.json', \
    'scenarios/powerwall/seattle-22.json', \
    'scenarios/powerwall/seattle-23.json', \
    'scenarios/powerwall/seattle-24.json', \
    'scenarios/powerwall/seattle-25.json', \
    'scenarios/powerwall/seattle-26.json', \
    'scenarios/powerwall/seattle-27.json', \
    'scenarios/powerwall/seattle-28.json', \
    'scenarios/powerwall/seattle-29.json', \
    'scenarios/powerwall/seattle-30.json', \
    'scenarios/powerwall/seattle-31.json', \
    'scenarios/powerwall/seattle-32.json', \
    'scenarios/powerwall/seattle-33.json', \
    'scenarios/powerwall/seattle-34.json', \
    'scenarios/powerwall/seattle-35.json', \
    'scenarios/powerwall/seattle-36.json', \
    'scenarios/powerwall/seattle-37.json', \
    'scenarios/powerwall/seattle-38.json', \
    'scenarios/powerwall/seattle-39.json', \
    'scenarios/powerwall/seattle-40.json', \
    'scenarios/powerwall/seattle-41.json', \
    'scenarios/powerwall/seattle-42.json', \
    'scenarios/powerwall/seattle-43.json', \
    'scenarios/powerwall/seattle-44.json', \
    'scenarios/powerwall/seattle-45.json', \
    'scenarios/powerwall/seattle-46.json', \
    'scenarios/powerwall/seattle-47.json', \
    'scenarios/powerwall/seattle-48.json', \
    'scenarios/powerwall/seattle-49.json', \
    'scenarios/powerwall/seattle-50.json', \
    'scenarios/powerwall/seattle-51.json', \
    'scenarios/powerwall/seattle-52.json' \
)


calibrateMain()
~~~
