~~~ markdown-script
# Licensed under the MIT License
# https://github.com/craigahobbs/tespo/blob/main/LICENSE

include 'powerwall.mds'
include 'tespo.mds'


async function tespoMain()
    # Input/output schema documentation?
    if vDoc != null then
        docTypeName = if(vDoc == 'output', 'TespoOutput', \
            if(vDoc == 'input', 'TespoInput', \
            if(vDoc == 'vehicle', 'VehicleScenario', \
            if(vDoc == 'powerwall', 'PowerwallScenario'))))
        setDocumentTitle(docTypeName)
        markdownPrint('[Home](#var=)')
        elementModelRender(schemaElements(powerwallTypes, docTypeName))
        return
    endif

    # Coming soon!
    title = 'TESPO'
    setDocumentTitle(title)
    markdownPrint( \
        '# ' + markdownEscape(title), \
        '', \
        'Coming soon!', \
        '', \
        '## Documentation', \
        '', \
        "[TESPO Input](#var.vDoc='input')", \
        '', \
        "[TESPO Output](#var.vDoc='output')", \
        '', \
        "[Powerwall Scenario](#var.vDoc='powerwall')", \
        '', \
        "[Vehicle Scenario](#var.vDoc='vehicle')", \
        '', \
        '## Powerwall Scenarios', \
        '', \
        "[Seattle, March](#url=calibrate.md&var.vScenarioURL='scenarios/powerwall/seattle-03.json')", \
        '', \
        "[Seattle, April](#url=calibrate.md&var.vScenarioURL='scenarios/powerwall/seattle-04.json')", \
        '', \
        "[Seattle, May](#url=calibrate.md&var.vScenarioURL='scenarios/powerwall/seattle-05.json')", \
        '', \
        "[Seattle, June](#url=calibrate.md&var.vScenarioURL='scenarios/powerwall/seattle-06.json')", \
        '', \
        "[Seattle, September](#url=calibrate.md&var.vScenarioURL='scenarios/powerwall/seattle-09.json')", \
        '', \
        "[Seattle, December](#url=calibrate.md&var.vScenarioURL='scenarios/powerwall/seattle-12.json')", \
        '' \
    )
endfunction


# Execute the main entry point
tespoMain()
~~~
