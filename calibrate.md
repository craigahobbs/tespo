# TESPO Simulation Calibration

~~~ markdown-script
include 'tesla.mds'


async function main()
    # Load the system specifications
    system = teslaValidateSystem(fetch('data/system.json'))

    # Load the data
    data = dataParseCSV(fetch('data-raw/2023-03-25.csv', null, true))

    # Simulate the data
    simulated = teslaSimulate(system, data)

    # Chart constants
    chartWidth = 1000
    chartHeight = 210
    fontSize = getDocumentFontSize()

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
