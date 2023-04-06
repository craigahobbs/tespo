# TESPO Simulation Calibration

~~~ markdown-script
include 'tesla.mds'


async function calibrateMain()
    # Load the scenario
    scenario = if(vScenarioURL != null, teslaLoadPowerwallScenario(vScenarioURL))
    if scenario == null then
        markdownPrint('Failed to load scenario URL "' + vScenarioURL + '"')
        return
    endif
    data = objectGet(scenario, 'data')

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
    simulated = teslaPowerwallSimulate(scenario)

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
        powerwallDiff = objectGet(rowSimulated, teslaFieldPowerwall) - objectGet(row, teslaFieldPowerwall)
        gridDiff = objectGet(rowSimulated, teslaFieldGrid) - objectGet(row, teslaFieldGrid)
        batteryDiff = objectGet(rowSimulated, teslaFieldBatteryPercent) - objectGet(row, teslaFieldBatteryPercent)

        # Update the Manhattan distance sums
        powerwallManhattanSum = powerwallManhattanSum + powerwallDiff * powerwallDiff
        gridManhattanSum = gridManhattanSum + gridDiff * gridDiff
        batteryManhattanSum = batteryManhattanSum + batteryDiff * batteryDiff

        # Update the Euclidian distance sums
        powerwallEuclidianSum = powerwallEuclidianSum + mathAbs(powerwallDiff)
        gridEuclidianSum = gridEuclidianSum + mathAbs(gridDiff)
        batteryEuclidianSum = batteryEuclidianSum + mathAbs(batteryDiff)

        # Add the differences data row
        arrayPush(differences, objectNew( \
            teslaFieldDate, objectGet(row, teslaFieldDate), \
            teslaFieldPowerwall, powerwallDiff, \
            teslaFieldGrid, gridDiff, \
            teslaFieldBatteryPercent, batteryDiff \
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
    chartWidth = 1000
    chartHeight = 210
    fontSize = getDocumentFontSize()

    # Controls
    markdownPrint( \
        '', \
        '**Scenario:** ' + markdownEscape(objectGet(scenario, 'name')), \
        '', \
        '**Battery Capacity:** ' + numberToFixed(batteryCapacity, 1) + '&nbsp;&nbsp;', \
        '[Up](' + calibrateURL(objectNew('batteryCapacity', mathMin(batteryCapacity + 0.5, 100)), scenario) + ')', \
        '[Down](' +  calibrateURL(objectNew('batteryCapacity', mathMax(batteryCapacity - 0.5, 1)), scenario) + ') \\', \
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
        'Note: Error values reported as Manhattan distance / Euclidian distance.', \
        '', \
        '---' \
    )

    # Difference data
    dataLineChart(differences, objectNew( \
        'title', 'Simulated Powerwall/Grid Difference', \
        'width', chartWidth, \
        'height', chartHeight, \
        'x', teslaFieldDate, \
        'y', arrayNew(teslaFieldPowerwall, teslaFieldGrid), \
        'yTicks', objectNew('count', 2), \
        'yLines', arrayNew(objectNew('value', 0)) \
    ))
    dataLineChart(differences, objectNew( \
        'title', 'Simulated Battery Difference', \
        'width', chartWidth - mathFloor(10 * fontSize), \
        'height', chartHeight, \
        'x', teslaFieldDate, \
        'y', arrayNew(teslaFieldBatteryPercent), \
        'yTicks', objectNew('count', 2), \
        'yLines', arrayNew(objectNew('value', 0)) \
    ))
    markdownPrint('', '---')

    # Home/Solar data
    dataLineChart(data, objectNew( \
        'title', 'Home/Solar', \
        'width', chartWidth - mathFloor(2.5 * fontSize), \
        'height', chartHeight, \
        'x', teslaFieldDate, \
        'y', arrayNew(teslaFieldHome, teslaFieldSolar), \
        'yTicks', objectNew('start', 0) \
    ))
    markdownPrint('', '---')

    # Powerwall/Grid
    dataLineChart(data, objectNew( \
        'title', 'Actual Powerwall/Grid', \
        'width', chartWidth, \
        'height', chartHeight, \
        'x', teslaFieldDate, \
        'y', arrayNew(teslaFieldPowerwall, teslaFieldGrid), \
        'yTicks', objectNew('count', 2), \
        'yLines', arrayNew(objectNew('value', 0)) \
    ))
    dataLineChart(simulated, objectNew( \
        'title', 'Simulated Powerwall/Grid', \
        'width', chartWidth, \
        'height', chartHeight, \
        'x', teslaFieldDate, \
        'y', arrayNew(teslaFieldPowerwall, teslaFieldGrid), \
        'yTicks', objectNew('count', 2), \
        'yLines', arrayNew(objectNew('value', 0)) \
    ))
    markdownPrint('', '---')

    # Battery
    dataLineChart(data, objectNew( \
        'title', 'Actual Battery', \
        'width', chartWidth - mathFloor(10 * fontSize), \
        'height', chartHeight, \
        'x', teslaFieldDate, \
        'y', arrayNew(teslaFieldBatteryPercent), \
        'yTicks', objectNew('start', 0, 'end', 100), \
        'yLines', arrayNew(objectNew('value', backupPercent)) \
    ))
    dataLineChart(simulated, objectNew( \
        'title', 'Simulated Battery', \
        'width', chartWidth - mathFloor(10 * fontSize), \
        'height', chartHeight, \
        'x', teslaFieldDate, \
        'y', arrayNew(teslaFieldBatteryPercent), \
        'yTicks', objectNew('start', 0, 'end', 100), \
        'yLines', arrayNew(objectNew('value', backupPercent)) \
    ))
    markdownPrint('', '---')

    # Simulated data table
    dataTable(dataJoin(data, simulated, '[' + teslaFieldDate + ']'), objectNew( \
        'fields', arrayNew( \
            teslaFieldDate, \
            teslaFieldHome, \
            teslaFieldSolar, \
            teslaFieldPowerwall, \
            teslaFieldGrid, \
            teslaFieldBatteryPercent, \
            teslaFieldPowerwall + '2', \
            teslaFieldGrid + '2', \
            teslaFieldBatteryPercent + '2' \
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
    if(batteryCapacity != null, arrayPush(parts, 'var.vBatteryCapacity=' + batteryCapacity))
    if(backupPercent != null, arrayPush(parts, 'var.vBackupPercent=' + backupPercent))
    if(chargeRatio != null, arrayPush(parts, 'var.vChargeRatio=' + mathRound(chargeRatio, ratioPrecicion)))
    if(dischargeRatio != null, arrayPush(parts, 'var.vDischargeRatio=' + mathRound(dischargeRatio, ratioPrecicion)))
    if(precision != null, arrayPush(parts, 'var.vPrecision=' + precision))
    return if(arrayLength(parts), '#' + arrayJoin(parts, '&'), '#var=')
endfunction


# Variable argument defaults
calibrateDefaultPrecision = 3


calibrateMain()
~~~
