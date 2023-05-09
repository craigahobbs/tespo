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
        '## Powerwall Scenario Calibration', \
        '', \
        '[Scenario Calibration](#url=calibrate.md)', \
        '', \
        '## TESPO Simulations', \
        '', \
        '[Simulations](#url=scenarios.md)' \
    )
endfunction


# Execute the main entry point
tespoMain()
~~~
