~~~ markdown-script
# Licensed under the MIT License
# https://github.com/craigahobbs/tespo/blob/main/LICENSE

include 'powerwall.mds'


async function calibrateMain():
    # Render the selected scenario, if requested
    if vScenarioURL != null:
        calibrateDetail()
        return
    endif

    # Render the scenario index
    calibrateIndex()
endfunction


async function calibrateIndex():
    # Set the title
    title = 'TESPO Powerwall Scenario Calibration'
    documentSetTitle(title)
    markdownPrint('[Home](#url=&var=)', '', '# ' + markdownEscape(title))

    # Fetch the scenario files
    powerwallScenarioURLs = systemFetch('scenarios/powerwallScenarioURLs.json')
    powerwallScenarioJSONs = systemFetch(powerwallScenarioURLs)

    # Create the scenario table's data
    scenarioTable = arrayNew()
    for scenarioJSON, ixScenario in powerwallScenarioJSONs:
        scenarioURL = arrayGet(powerwallScenarioURLs, ixScenario)
        scenarioName = objectGet(scenarioJSON, 'name')
        arrayPush(scenarioTable, objectNew( \
            'Scenario', '[' + markdownEscape(scenarioName) + '](' + calibrateURL(objectNew('scenarioURL', scenarioURL)) + ')', \
            'Battery Capacity (kWh)', objectGet(scenarioJSON, 'batteryCapacity'), \
            'Backup (%)', objectGet(scenarioJSON, 'backupPercent'), \
            'Charge Ratio', objectGet(scenarioJSON, 'chargeRatio'), \
            'Discharge Ratio', objectGet(scenarioJSON, 'dischargeRatio') \
        ))
    endfor

    # Render the scenario table
    dataTable(scenarioTable, objectNew( \
        'formats', objectNew( \
            'Scenario', objectNew('markdown', true) \
        ) \
    ))
endfunction


async function calibrateDetail():
    # Set the default title
    title = 'TESPO Simulation Scenario Calibration'
    documentSetTitle(title)

    # Load the scenario
    powerwallScenario = if(vScenarioURL != null, powerwallLoadScenario(vScenarioURL))
    if powerwallScenario == null:
        markdownPrint('Failed to load scenario URL "' + vScenarioURL + '"')
        return
    endif
    data = objectGet(powerwallScenario, 'data')
    scenarioName = objectGet(powerwallScenario, 'name')

    # Compute the prev/next scenario URLs
    baseScenarioURL = powerwallGetBaseURL(vScenarioURL)
    prevScenarioURL = objectGet(powerwallScenario, 'prevScenarioURL')
    if prevScenarioURL != null && powerwallIsRelativeURL(prevScenarioURL):
        prevScenarioURL = baseScenarioURL + prevScenarioURL
    endif
    nextScenarioURL = objectGet(powerwallScenario, 'nextScenarioURL')
    if nextScenarioURL != null && powerwallIsRelativeURL(nextScenarioURL):
        nextScenarioURL = baseScenarioURL + nextScenarioURL
    endif

    # Variable scenario overrides
    batteryCapacity = if(vBatteryCapacity, mathMax(1, vBatteryCapacity), objectGet(powerwallScenario, 'batteryCapacity'))
    backupPercent = if(vBackupPercent, mathMax(0, vBackupPercent), objectGet(powerwallScenario, 'backupPercent'))
    chargeRatio = if(vChargeRatio, mathMax(0.1, vChargeRatio), objectGet(powerwallScenario, 'chargeRatio'))
    dischargeRatio = if(vDischargeRatio, mathMax(0.1, vDischargeRatio), objectGet(powerwallScenario, 'dischargeRatio'))
    precision = if(vPrecision, mathMax(1, mathRound(vPrecision)), calibrateDefaultPrecision)
    ratioDelta = 0.1 ** precision

    # Update the Powerwall scenario
    objectSet(powerwallScenario, 'batteryCapacity', batteryCapacity)
    objectSet(powerwallScenario, 'backupPercent', backupPercent)
    objectSet(powerwallScenario, 'chargeRatio', chargeRatio)
    objectSet(powerwallScenario, 'dischargeRatio', dischargeRatio)

    # Auto-calibrate?
    if vAuto:
        calibrateAuto(powerwallScenario)
        windowSetLocation(calibrateURL( \
            objectNew( \
                'batteryCapacity', objectGet(powerwallScenario, 'batteryCapacity'), \
                'backupPercent', objectGet(powerwallScenario, 'backupPercent'), \
                'chargeRatio', objectGet(powerwallScenario, 'chargeRatio'), \
                'dischargeRatio', objectGet(powerwallScenario, 'dischargeRatio'), \
                'auto', 0 \
            ), \
            powerwallScenario \
        ))
        return
    endif

    # Simulate grid, powerwall, and battery percentage
    simulated = powerwallSimulate(powerwallScenario, powerwallBatteryPercent(powerwallScenario))

    # Compute the differences
    differences = arrayNew()
    powerwallManhattanSum = 0
    gridManhattanSum = 0
    batteryManhattanSum = 0
    powerwallEuclidianSum = 0
    gridEuclidianSum = 0
    batteryEuclidianSum = 0
    for row, ixRow in data:
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
    endfor

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
    fontSize = documentFontSize()

    # Controls
    documentSetTitle(scenarioName)
    markdownPrint( \
        '[Back](#var=)', \
        '', \
        '# ' + title, \
        '', \
        '**Scenario:** ' + markdownEscape(scenarioName) + if(prevScenarioURL == null && nextScenarioURL == null, '', '&nbsp;&nbsp;(' + \
            if(prevScenarioURL != null, '[Previous](' + calibrateURL(objectNew('scenarioURL', prevScenarioURL)) + ')', 'Previous') + \
            '&nbsp;|&nbsp;' + \
            if(nextScenarioURL != null, '[Next](' + calibrateURL(objectNew('scenarioURL', nextScenarioURL)) + ')', 'Next') + \
            ')' \
        ), \
        '', \
        '**Battery Capacity:** ' + numberToFixed(batteryCapacity, 1) + '&nbsp;&nbsp;', \
        '[Up](' + calibrateURL(objectNew('batteryCapacity', mathMin(batteryCapacity + 0.1, 100)), powerwallScenario) + ')', \
        '[Down](' +  calibrateURL(objectNew('batteryCapacity', mathMax(batteryCapacity - 0.1, 1)), powerwallScenario) + ') \\', \
        '**Backup Percent:** ' + backupPercent + '&nbsp;&nbsp;', \
        '[Up](' + calibrateURL(objectNew('backupPercent', mathMin(backupPercent + 1, 100)), powerwallScenario) + ')', \
        '[Down](' + calibrateURL(objectNew('backupPercent', mathMax(backupPercent - 1, 0)), powerwallScenario) + ') \\', \
        '**Charge Ratio:** ' + numberToFixed(chargeRatio, precision) + '&nbsp;&nbsp;', \
        '[Up](' + calibrateURL(objectNew('chargeRatio', chargeRatio + ratioDelta), powerwallScenario) + ')', \
        '[Down](' + calibrateURL(objectNew('chargeRatio', mathMax(chargeRatio - ratioDelta, ratioDelta)), powerwallScenario) + ') \\', \
        '**Discharge Ratio:** ' + numberToFixed(dischargeRatio, precision) + '&nbsp;&nbsp;', \
        '[Up](' + calibrateURL(objectNew('dischargeRatio', dischargeRatio + ratioDelta), powerwallScenario) + ')', \
        '[Down](' + calibrateURL(objectNew('dischargeRatio', mathMax(dischargeRatio - ratioDelta, ratioDelta)), powerwallScenario) + ') \\', \
        '**Precision:** ' + precision + '&nbsp;&nbsp;', \
        '[Up](' + calibrateURL(objectNew('precision', precision + 1), powerwallScenario) + ')', \
        '[Down](' + calibrateURL(objectNew('precision', mathMax(precision - 1, 1)), powerwallScenario) + ') \\', \
        '[Reset](' + calibrateURL(objectNew(), null) + ') | ', \
        '[Auto](' + calibrateURL(objectNew('auto', 1), powerwallScenario) + ')', \
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
    for row, ixRow in data:
        rowSimulated = arrayGet(simulated, ixRow)
        objectSet(row, 'Simulated ' + powerwallFieldPowerwall, objectGet(rowSimulated, powerwallFieldPowerwall))
        objectSet(row, 'Simulated ' + powerwallFieldGrid, objectGet(rowSimulated, powerwallFieldGrid))
        objectSet(row, 'Simulated ' + powerwallFieldBatteryPercent, objectGet(rowSimulated, powerwallFieldBatteryPercent))
    endfor
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


function calibrateAuto(powerwallScenario):
    batteryCapacity = objectGet(powerwallScenario, 'batteryCapacity')
    chargeRatio = objectGet(powerwallScenario, 'chargeRatio')
    dischargeRatio = objectGet(powerwallScenario, 'dischargeRatio')

    # Compute the initial difference
    minDiff = getSimulatedDiff(powerwallScenario)

    # Iteratively make adjustments to battery capacity, charge ratio, and discharge ratio
    iter = 0
    changed = true
    while changed && iter < 10:
        changed = false

        # Adjust the battery capacity until we hit a local minimum
        batteryCapacityDelta = 0.1
        while batteryCapacity < 1000:
            batteryCapacity = batteryCapacity + batteryCapacityDelta
            objectSet(powerwallScenario, 'batteryCapacity', batteryCapacity)
            diff = getSimulatedDiff(powerwallScenario)
            if diff > minDiff:
                batteryCapacity = batteryCapacity - batteryCapacityDelta
                objectSet(powerwallScenario, 'batteryCapacity', batteryCapacity)
                break
            endif
            minDiff = diff
            changed = true
        endwhile
        while batteryCapacity > 1:
            batteryCapacity = batteryCapacity - batteryCapacityDelta
            objectSet(powerwallScenario, 'batteryCapacity', batteryCapacity)
            diff = getSimulatedDiff(powerwallScenario)
            if diff > minDiff:
                batteryCapacity = batteryCapacity + batteryCapacityDelta
                objectSet(powerwallScenario, 'batteryCapacity', batteryCapacity)
                break
            endif
            minDiff = diff
            changed = true
        endwhile

        # Adjust the charge ratio until we hit a local minimum
        chargeRatioDelta = 0.01
        while chargeRatio < 1:
            chargeRatio = chargeRatio + chargeRatioDelta
            objectSet(powerwallScenario, 'chargeRatio', chargeRatio)
            diff = getSimulatedDiff(powerwallScenario)
            if diff > minDiff:
                chargeRatio = chargeRatio - chargeRatioDelta
                objectSet(powerwallScenario, 'chargeRatio', chargeRatio)
                break
            endif
            minDiff = diff
            changed = true
        endwhile
        while chargeRatio > 0.85:
            chargeRatio = chargeRatio - chargeRatioDelta
            objectSet(powerwallScenario, 'chargeRatio', chargeRatio)
            diff = getSimulatedDiff(powerwallScenario)
            if diff > minDiff:
                chargeRatio = chargeRatio + chargeRatioDelta
                objectSet(powerwallScenario, 'chargeRatio', chargeRatio)
                break
            endif
            minDiff = diff
            changed = true
        endwhile

        # Adjust the charge ratio until we hit a local minimum
        dischargeRatioDelta = 0.01
        while dischargeRatio < 1:
            dischargeRatio = dischargeRatio + dischargeRatioDelta
            objectSet(powerwallScenario, 'dischargeRatio', dischargeRatio)
            diff = getSimulatedDiff(powerwallScenario)
            if diff > minDiff:
                dischargeRatio = dischargeRatio - dischargeRatioDelta
                objectSet(powerwallScenario, 'dischargeRatio', dischargeRatio)
                break
            endif
            minDiff = diff
            changed = true
        endwhile
        while dischargeRatio > 0.85:
            dischargeRatio = dischargeRatio - dischargeRatioDelta
            objectSet(powerwallScenario, 'dischargeRatio', dischargeRatio)
            diff = getSimulatedDiff(powerwallScenario)
            if diff > minDiff:
                dischargeRatio = dischargeRatio + dischargeRatioDelta
                objectSet(powerwallScenario, 'dischargeRatio', dischargeRatio)
                break
            endif
            minDiff = diff
            changed = true
        endwhile

        iter = iter + 1
    endwhile
endfunction


# Compute the Manhattan distance between the actual and simulate battery percentage
function getSimulatedDiff(powerwallScenario):
    data = objectGet(powerwallScenario, 'data')
    simulated = powerwallSimulate(powerwallScenario, powerwallBatteryPercent(powerwallScenario))
    batteryPercentManhattanSum = 0
    for row, ixRow in data:
        rowSimulated = arrayGet(simulated, ixRow)
        batteryPercentDiff = objectGet(rowSimulated, powerwallFieldBatteryPercent) - objectGet(row, powerwallFieldBatteryPercent)
        batteryPercentManhattanSum = batteryPercentManhattanSum + mathAbs(batteryPercentDiff)
    endfor
    return batteryPercentManhattanSum / arrayLength(data)
endfunction


# Helper to create calibrate application URLs
function calibrateURL(args, powerwallScenario):
    # URL arguments
    scenarioURL = if(objectHas(args, 'scenarioURL'), objectGet(args, 'scenarioURL'), vScenarioURL)

    # Powerwall scenario URL arguments
    if powerwallScenario != null:
        batteryCapacity = if(objectHas(args, 'batteryCapacity'), objectGet(args, 'batteryCapacity'), vBatteryCapacity)
        backupPercent = if(objectHas(args, 'backupPercent'), objectGet(args, 'backupPercent'), vBackupPercent)
        chargeRatio = if(objectHas(args, 'chargeRatio'), objectGet(args, 'chargeRatio'), vChargeRatio)
        dischargeRatio = if(objectHas(args, 'dischargeRatio'), objectGet(args, 'dischargeRatio'), vDischargeRatio)
        precision = if(objectHas(args, 'precision'), objectGet(args, 'precision'), vPrecision)
        auto = if(objectHas(args, 'auto'), objectGet(args, 'auto'), vAuto)

        # Set defaults from the scenario
        batteryCapacity = if(batteryCapacity != null, batteryCapacity, objectGet(powerwallScenario, 'batteryCapacity'))
        backupPercent = if(backupPercent != null, backupPercent, objectGet(powerwallScenario, 'backupPercent'))
        chargeRatio = if(chargeRatio != null, chargeRatio, objectGet(powerwallScenario, 'chargeRatio'))
        dischargeRatio = if(dischargeRatio != null, dischargeRatio, objectGet(powerwallScenario, 'dischargeRatio'))
    endif

    # Create the URL
    parts = arrayNew()
    ratioPrecision = if(vPrecision != null, vPrecision, calibrateDefaultPrecision)
    arrayPush(parts, "var.vScenarioURL='" + urlEncodeComponent(scenarioURL) + "'")
    if(batteryCapacity != null, arrayPush(parts, 'var.vBatteryCapacity=' + mathRound(batteryCapacity, 1)))
    if(backupPercent != null, arrayPush(parts, 'var.vBackupPercent=' + mathRound(backupPercent, 1)))
    if(chargeRatio != null, arrayPush(parts, 'var.vChargeRatio=' + mathRound(chargeRatio, ratioPrecision)))
    if(dischargeRatio != null, arrayPush(parts, 'var.vDischargeRatio=' + mathRound(dischargeRatio, ratioPrecision)))
    if(precision != null, arrayPush(parts, 'var.vPrecision=' + precision))
    if(auto != null, arrayPush(parts, 'var.vAuto=' + auto))
    return if(arrayLength(parts), '#' + arrayJoin(parts, '&'), '#var=')
endfunction


# Variable argument defaults
calibrateDefaultPrecision = 2


calibrateMain()
~~~
