~~~ markdown-script
# Licensed under the MIT License
# https://github.com/craigahobbs/tespo/blob/main/LICENSE

include 'tespo.mds'


async function main()
    # Input schema documentation?
    if vDocInput then
        markdownPrint('[Home](#var=)', '')
        elementModelRender(schemaElements(tespoTypes, 'TespoInput'))
        return

    # Output schema documentation?
    else if vDocOutput then
        markdownPrint('[Home](#var=)', '')
        elementModelRender(schemaElements(tespoTypes, 'TespoOutput'))
        return
    endif

    # Determine the scenario input URL
    scenarioName = if(vScenario != null, vScenario, defaultScenarioName)
    inputURL = objectGet(scenarios, scenarioName)
    if inputURL == null then
        inputURL = objectGet(scenarios, defaultScenarioName)
    endif

    # Fetch the TESPO input
    input = schemaValidate(tespoTypes, 'TespoInput', fetch(inputURL))

    # Compute the TESPO output
    output = schemaValidate(tespoTypes, 'TespoOutput', tespo(input))

    # Create the scenario links markdown
    scenarioLinks = ''
    foreach scenarioLinkName, ixScenario in scenarioNames do
        scenarioLinks = scenarioLinks + if(ixScenario != 0, ' | ', '') + \
            if(scenarioLinkName == scenarioName, scenarioLinkName, '[' + scenarioLinkName + "](#var.vScenario='" + scenarioLinkName + "')")
    endforeach

    # Main display
    markdownPrint( \
        '# Tesla Energy Self-Powered Optimizer', \
        '', \
        scenarioLinks, \
        '', \
        '**Scenario:** ' + scenarioName, \
        '', \
        '### Output', \
        '', \
        '[Output Schema Documentation](#var.vDocOutput=1)', \
        '', \
        '~~~', \
        jsonStringify(output, 4), \
        '~~~', \
        '', \
        '### Input', \
        '', \
        '[Input Schema Documentation](#var.vDocInput=1)', \
        '', \
        '~~~', \
        jsonStringify(input, 4), \
        '~~~' \
    )
endfunction


# Input scenario name to URL map
scenarios = objectNew( \
    'AllCharged', 'input/allCharged.json', \
    'HomeCharged', 'input/homeCharged.json', \
    'HomeCharged-LowSolar', 'input/homeCharged-lowSolar.json', \
    'HomeCharged-MedSolar', 'input/homeCharged-medSolar.json', \
    'HomeCharged-ZeroSolar', 'input/homeCharged-zeroSolar.json', \
    'NoneCharged', 'input/noneCharged.json' \
)
scenarioNames = objectKeys(scenarios)
defaultScenarioName = 'AllCharged'


# Execute the main entry point
main()
~~~
