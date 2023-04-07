~~~ markdown-script
# Licensed under the MIT License
# https://github.com/craigahobbs/tespo/blob/main/LICENSE

include 'powerwall.mds'
include 'tespo.mds'


async function tespoMain()
    # Input/output schema documentation?
    if vDocOutput || vDocInput then
        typeName = if(vDocOutput, 'TespoOutput', 'TespoInput')
        setDocumentTitle(typeName)
        markdownPrint('[Home](#var=)')
        elementModelRender(schemaElements(tespoTypes, typeName))
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
