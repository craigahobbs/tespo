# TESPO Simulation Calibration

~~~ markdown-script
include 'tesla.mds'


async function main()
    # System variable-overrides
    batteryCapacity = if(vBatteryCapacity, mathMax(1, vBatteryCapacity), 40.5)
    backupPercent = if(vBackupPercent, mathMax(0, vBackupPercent), 20)
    chargeRatio = if(vChargeRatio, mathMax(0.1, vChargeRatio), 0.9)
    dischargeRatio = if(vDischargeRatio, mathMax(0.1, vDischargeRatio), 0.9)
    precision = if(vPrecision, mathMax(1, mathRound(vPrecision)), 3)
    ratioDelta = 0.1 ** precision

    # Load the data
    data = dataParseCSV(fetch('data-raw/2023-03-25.csv', null, true))

    # Simulate the data
    system = objectNew( \
        'usableEnergy', batteryCapacity, \
        'backupPercent', backupPercent, \
        'chargeRatio', chargeRatio, \
        'dischargeRatio', dischargeRatio \
    )
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

    # Controls
    markdownPrint( \
        '', \
        '**Battery Capacity:** ' + numberToFixed(batteryCapacity, precision) + '&nbsp;&nbsp;', \
        link('Up', batteryCapacity + ratioDelta, backupPercent, chargeRatio, dischargeRatio, precision) + ' |', \
        link('Down', mathMax(batteryCapacity - ratioDelta, 1), backupPercent, mathMax(chargeRatio, ratioDelta), dischargeRatio, precision) + ' \\', \
        '**Backup Percent:** ' + numberToFixed(backupPercent, precision) + '&nbsp;&nbsp;', \
        link('Up', batteryCapacity, mathMin(backupPercent + 1, 100), chargeRatio, dischargeRatio, precision) + ' |', \
        link('Down', batteryCapacity, mathMax(backupPercent - 1, 0), mathMax(chargeRatio, ratioDelta), dischargeRatio, precision) + ' \\', \
        '**Charge Ratio:** ' + numberToFixed(chargeRatio, precision) + '&nbsp;&nbsp;', \
        link('Up', batteryCapacity, backupPercent, chargeRatio + ratioDelta, dischargeRatio, precision) + ' |', \
        link('Down', batteryCapacity, backupPercent, mathMax(chargeRatio - ratioDelta, ratioDelta), dischargeRatio, precision) + ' \\', \
        '**Discharge Ratio:** ' + numberToFixed(dischargeRatio, precision) + '&nbsp;&nbsp;', \
        link('Up', batteryCapacity, backupPercent, chargeRatio, dischargeRatio + ratioDelta, precision) + ' |', \
        link('Down', batteryCapacity, backupPercent, chargeRatio, mathMax(dischargeRatio - ratioDelta, ratioDelta), precision) + ' \\', \
        '**Precision:** ' + precision + '&nbsp;&nbsp;', \
        link('Up', batteryCapacity, backupPercent, chargeRatio, dischargeRatio, precision + 1) + ' |', \
        link('Down', batteryCapacity, backupPercent, chargeRatio, dischargeRatio, mathMax(1, precision - 1)), \
        '', \
        '---' \
    )

    # Difference
    markdownPrint( \
        '', \
        '**Manhattan Distance:** \\', \
        '&nbsp;&nbsp;&nbsp;&nbsp;**Powerwall:** ' + numberToFixed(powerwallManhattanDistance, precision) + ' \\', \
        '&nbsp;&nbsp;&nbsp;&nbsp;**Grid:** ' + numberToFixed(gridManhattanDistance, precision) + ' \\', \
        '&nbsp;&nbsp;&nbsp;&nbsp;**Battery:** ' + numberToFixed(batteryManhattanDistance, precision), \
        '', \
        '**Euclidian Distance:** \\', \
        '&nbsp;&nbsp;&nbsp;&nbsp;**Powerwall:** ' + numberToFixed(powerwallEuclidianDistance, precision) + ' \\', \
        '&nbsp;&nbsp;&nbsp;&nbsp;**Grid:** ' + numberToFixed(gridEuclidianDistance, precision) + ' \\', \
        '&nbsp;&nbsp;&nbsp;&nbsp;**Battery:** ' + numberToFixed(batteryEuclidianDistance, precision), \
        '', \
        '---' \
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


function link(text, batteryCapacity, backupPercent, chargeRatio, dischargeRatio, precision)
    return '[' + text + '](#' + \
        'var.vBatteryCapacity=' + numberToFixed(batteryCapacity, precision) + \
        '&var.vBackupPercent=' + numberToFixed(backupPercent, precision) + \
        '&var.vChargeRatio=' + numberToFixed(chargeRatio, precision) + \
        '&var.vDischargeRatio=' + numberToFixed(dischargeRatio, precision) + \
        '&var.vPrecision=' + precision + ')'
endfunction


main()
~~~
