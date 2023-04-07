~~~ markdown-script
# Licensed under the MIT License
# https://github.com/craigahobbs/tespo/blob/main/LICENSE

include 'powerwall.mds'
include 'tespo.mds'


async function tespoMain()
    # Input/output schema documentation?
    if vDoc != null then
        docTypes = if(vDoc == 'powerwall', powerwallTypes, tespoTypes)
        docTypeName = if(vDoc == 'output', 'TespoOutput', \
            if(vDoc == 'input', 'TespoInput', \
            if(vDoc == 'vehicle', 'VehicleScenario', \
            if(vDoc == 'powerwall', 'PowerwallScenario'))))
        setDocumentTitle(docTypeName)
        markdownPrint('[Home](#var=)')
        elementModelRender(schemaElements(docTypes, docTypeName))
        return
    endif

    # Coming soon!
    title = 'TESPO'
    setDocumentTitle(title)
    markdownPrint( \
        '# ' + markdownEscape(title), \
        '', \
        'Coming soon!' \
    )
endfunction


# Execute the main entry point
tespoMain()
~~~
