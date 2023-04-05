# TESPO Simulation Calibration

~~~ markdown-script
include 'tesla.mds'


async function main()
    # Load the system specifications
    system = teslaValidateSystem(fetch('data/system.json'))

    # System variable-overrides
    if vCharge then
        objectSet(system, 'chargeRatio', vCharge)
    endif
    if vDischarge then
        objectSet(system, 'dischargeRatio', vDischarge)
    endif

    # Load the data
    data = dataParseCSV(fetch('data-raw/2023-03-25.csv', null, true))

    # Simulate the data
    simulated = teslaSimulate(system, data)

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

    # Difference
    markdownPrint( \
        '', \
        '**Manhattan Distance:** \\', \
        '&nbsp;&nbsp;&nbsp;&nbsp;**Powerwall:** ' + numberToFixed(powerwallManhattanDistance) + ' \\', \
        '&nbsp;&nbsp;&nbsp;&nbsp;**Grid:** ' + numberToFixed(gridManhattanDistance) + ' \\', \
        '&nbsp;&nbsp;&nbsp;&nbsp;**Battery:** ' + numberToFixed(batteryManhattanDistance), \
        '', \
        '**Euclidian Distance:** \\', \
        '&nbsp;&nbsp;&nbsp;&nbsp;**Powerwall:** ' + numberToFixed(powerwallEuclidianDistance) + ' \\', \
        '&nbsp;&nbsp;&nbsp;&nbsp;**Grid:** ' + numberToFixed(gridEuclidianDistance) + ' \\', \
        '&nbsp;&nbsp;&nbsp;&nbsp;**Battery:** ' + numberToFixed(batteryEuclidianDistance) \
    )
    dataLineChart(differences, objectNew( \
        'title', 'Simulated Powerwall/Grid Difference', \
        'width', chartWidth - mathFloor(2.5 * fontSize), \
        'height', chartHeight, \
        'x', teslaFieldDate, \
        'y', arrayNew(teslaFieldPowerwall, teslaFieldGrid), \
        'yLines', arrayNew(objectNew('value', 0)) \
    ))
    dataLineChart(differences, objectNew( \
        'title', 'Simulated Battery Difference', \
        'width', chartWidth - mathFloor(2.5 * fontSize), \
        'height', chartHeight, \
        'x', teslaFieldDate, \
        'y', arrayNew(teslaFieldBatteryPercent), \
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
        'yTicks', objectNew('start', 0, 'end', 12) \
    ))
    markdownPrint('', '---')

    # Powerwall/Grid
    dataLineChart(data, objectNew( \
        'title', 'Powerwall/Grid', \
        'width', chartWidth, \
        'height', chartHeight, \
        'x', teslaFieldDate, \
        'y', arrayNew(teslaFieldPowerwall, teslaFieldGrid), \
        'yTicks', objectNew('start', -10, 'end', 10) \
    ))
    dataLineChart(simulated, objectNew( \
        'title', 'Simulated Powerwall/Grid', \
        'width', chartWidth, \
        'height', chartHeight, \
        'x', teslaFieldDate, \
        'y', arrayNew(teslaFieldPowerwall, teslaFieldGrid), \
        'yTicks', objectNew('start', -10, 'end', 10) \
    ))
    markdownPrint('', '---')

    # Battery
    backupPercent = objectGet(system, 'backupPercent')
    dataLineChart(data, objectNew( \
        'title', 'Battery', \
        'width', chartWidth - mathFloor(10 * fontSize), \
        'height', chartHeight, \
        'x', teslaFieldDate, \
        'y', arrayNew(teslaFieldBatteryPercent), \
        'yTicks', objectNew('start', 0, 'end', 100), \
        'yLines', arrayNew(objectNew('value', (backupPercent / 100) * batterySizeKWh)) \
    ))
    dataLineChart(simulated, objectNew( \
        'title', 'Simulated Battery', \
        'width', chartWidth - mathFloor(10 * fontSize), \
        'height', chartHeight, \
        'x', teslaFieldDate, \
        'y', arrayNew(teslaFieldBatteryPercent), \
        'yTicks', objectNew('start', 0, 'end', 100), \
        'yLines', arrayNew(objectNew('value', (backupPercent / 100) * batterySizeKWh)) \
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


main()
~~~
