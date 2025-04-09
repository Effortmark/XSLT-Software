<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
    xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
    xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"
    xmlns:z="http://schemas.openxmlformats.org/package/2006/relationships"
    xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
    xmlns:c="http://schemas.openxmlformats.org/drawingml/2006/chart"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="a r p z m c xs">

    <xsl:output method="html" indent="yes" version="5.0"/>
    <xsl:param name="debug">0</xsl:param>

    <!-- list of slides -->
    <xsl:variable name="slides" select="//file[contains(@name, 'slides/slide')]"/>

    <!-- list of slide rels -->
    <xsl:variable name="slides.rels" select="//file[contains(@name, 'slides/_rels/slide')]"/>

    <!-- list of slide layouts -->
    <xsl:variable name="slides.layout" select="//file[contains(@name, 'slideLayouts/slideLayout')]"/>

    <!-- list of slide layout rels -->
    <xsl:variable name="slides.layout.rels"
        select="//file[contains(@name, 'slideLayouts/_rels/slideLayout')]"/>

    <!-- list of slide master layouts -->
    <xsl:variable name="slides.master" select="//file[contains(@name, 'slideMasters/slideMaster')]"/>

    <!-- Add variables to track accessibility issues -->
    <xsl:variable name="missing_alt_text" select="//p:pic[not(p:nvPicPr/p:cNvPr/@descr) or p:nvPicPr/p:cNvPr/@descr='']"/>
    <xsl:variable name="small_text" select="//a:r[number(a:rPr/@sz) &lt; 1800]"/>
    <xsl:variable name="complex_tables" select="//a:tbl[count(.//a:tc) > 20]"/>
    <xsl:variable name="text_as_images" select="//p:pic[contains(p:nvPicPr/p:cNvPr/@name, 'Text') or contains(p:nvPicPr/p:cNvPr/@name, 'Word')]"/>
    <xsl:variable name="missing_slide_titles" select="//p:sld[not(.//p:sp[.//p:ph/@type='title' or .//p:ph/@type='ctrTitle'])]"/>
    <xsl:variable name="tables_without_headers" select="//a:tbl[not(a:tblPr/@firstRow='1')]"/>
    <xsl:variable name="hyperlinks_without_text" select="//a:r[a:rPr/a:hlinkClick and not(normalize-space(a:t))]"/>
    <xsl:variable name="long_alt_text" select="//p:pic[string-length(p:nvPicPr/p:cNvPr/@descr) > 150]"/>

    <!-- here is the start of the formatter -->
    <xsl:template match="/">
        <!-- Accessibility Summary -->
        <div class="accessibility-summary alert alert-info">
            <h2>Accessibility Review</h2>
            <p>Here are some issues that could affect the accessibility of your presentation:</p>
            <ul>
                <!-- Missing slide titles -->
                <xsl:if test="count($missing_slide_titles) > 0">
                    <li class="alert alert-warning">
                        <strong>Missing Slide Titles:</strong> Found <xsl:value-of select="count($missing_slide_titles)"/> slide(s) without titles. 
                        Each slide should have a unique title for navigation and screen reader support.
                        These are slides: 
                        <xsl:for-each select="$missing_slide_titles">
                            <span class="badge badge-warning"><xsl:value-of select="position()"/></span>
                            <xsl:if test="position() != last()">, </xsl:if>
                        </xsl:for-each>
                    </li>
                </xsl:if>

                <!-- Tables without headers -->
                <xsl:if test="count($tables_without_headers) > 0">
                    <li class="alert alert-warning">
                        <strong>Tables Without Headers:</strong> Found <xsl:value-of select="count($tables_without_headers)"/> table(s) that may be missing header rows.
                        Table headers help screen reader users understand the structure and content of tables.
                    </li>
                </xsl:if>

                <!-- Images without alt text -->
                <xsl:if test="count($missing_alt_text) > 0">
                    <li class="alert alert-warning">
                        <strong>Missing Alternative Text:</strong> Found <xsl:value-of select="count($missing_alt_text)"/> image(s) without descriptive alt text. 
                        These appear on slides: 
                        <!-- Group images by slide using XSLT 1.0 -->
                        <xsl:for-each select="$missing_alt_text[not(count(preceding::p:sld) = count(preceding-sibling::p:pic[not(p:nvPicPr/p:cNvPr/@descr) or p:nvPicPr/p:cNvPr/@descr='']/preceding::p:sld))]">
                            <xsl:variable name="current_slide" select="count(preceding::p:sld)"/>
                            <xsl:variable name="images_in_slide" select="count($missing_alt_text[count(preceding::p:sld) = $current_slide])"/>
                            <span class="badge badge-warning">
                                Slide <xsl:value-of select="$current_slide + 1"/> (<xsl:value-of select="$images_in_slide"/><xsl:text> </xsl:text><xsl:if test="$images_in_slide = 1">image</xsl:if><xsl:if test="$images_in_slide > 1">images</xsl:if>)
                            </span>
                            <xsl:if test="position() != last()">, </xsl:if>
                        </xsl:for-each>
                    </li>
                </xsl:if>

                <!-- Long alt text -->
                <xsl:if test="count($long_alt_text) > 0">
                    <li class="alert alert-warning">
                        <strong>Long Alternative Text:</strong> Found <xsl:value-of select="count($long_alt_text)"/> image(s) with very long alt text (over 150 characters).
                        Consider making the descriptions more concise or using the notes section for longer descriptions.
                    </li>
                </xsl:if>

                <!-- Hyperlinks without meaningful text -->
                <xsl:if test="count($hyperlinks_without_text) > 0">
                    <li class="alert alert-warning">
                        <strong>Empty Hyperlinks:</strong> Found <xsl:value-of select="count($hyperlinks_without_text)"/> hyperlink(s) without meaningful text.
                        Links should have descriptive text that makes sense when read out of context.
                    </li>
                </xsl:if>

                <!-- Small text -->
                <xsl:if test="count($small_text) > 0">
                    <li class="alert alert-warning">
                        <strong>Small Text:</strong> Found text that may be too small to read (less than 18pt).
                        Consider increasing the font size for better visibility.
                    </li>
                </xsl:if>

                <!-- Complex tables -->
                <xsl:if test="count($complex_tables) > 0">
                    <li class="alert alert-warning">
                        <strong>Complex Tables:</strong> Found <xsl:value-of select="count($complex_tables)"/> complex table(s) that might be difficult to navigate with screen readers.
                        Consider simplifying these tables or providing alternative formats.
                    </li>
                </xsl:if>

                <!-- Text as images -->
                <xsl:if test="count($text_as_images) > 0">
                    <li class="alert alert-warning">
                        <strong>Text as Images:</strong> Found <xsl:value-of select="count($text_as_images)"/> instance(s) of text saved as images.
                        This can make the content difficult to read with screen readers.
                    </li>
                </xsl:if>

                <!-- Color contrast check placeholder -->
                <li class="alert alert-info">
                    <strong>Color Contrast:</strong> Please check that your text has sufficient contrast with background colors.
                    The WCAG guidelines recommend a contrast ratio of at least 4.5:1 for normal text and 3:1 for large text.
                </li>

                <!-- Reading order reminder -->
                <li class="alert alert-info">
                    <strong>Reading Order:</strong> Ensure that the content is arranged in a logical reading order.
                    Screen readers will read content in the order it appears in the slide's structure.
                </li>
            </ul>

            <h3>Recommendations:</h3>
            <ol>
                <xsl:if test="count($missing_slide_titles) > 0">
                    <li>Add unique, descriptive titles to all slides</li>
                </xsl:if>
                <xsl:if test="count($tables_without_headers) > 0">
                    <li>Add header rows to tables to improve navigation and understanding</li>
                </xsl:if>
                <xsl:if test="count($missing_alt_text) > 0">
                    <li>Add descriptive alt text to all images and graphics</li>
                </xsl:if>
                <xsl:if test="count($long_alt_text) > 0">
                    <li>Make alt text more concise and use notes for longer descriptions</li>
                </xsl:if>
                <xsl:if test="count($hyperlinks_without_text) > 0">
                    <li>Ensure all hyperlinks have meaningful descriptive text</li>
                </xsl:if>
                <xsl:if test="count($small_text) > 0">
                    <li>Increase font sizes to at least 18pt for better readability</li>
                </xsl:if>
                <xsl:if test="count($complex_tables) > 0">
                    <li>Simplify complex tables or break them into smaller, more manageable tables</li>
                </xsl:if>
                <xsl:if test="count($text_as_images) > 0">
                    <li>Convert text in images to actual text content where possible</li>
                </xsl:if>
                <li>Use built-in slide layouts and templates to maintain consistent structure</li>
                <li>Ensure sufficient color contrast between text and backgrounds</li>
                <li>Use clear heading structures and reading order</li>
                <li>Avoid using color alone to convey information</li>
                <li>Consider adding slide notes to provide additional context</li>
            </ol>
        </div>

        <p class="lead">Total slides: <xsl:value-of select="count($slides)"/></p>

        <xsl:for-each select="$slides">
            <!-- sorting via num attribute (added via python script) -->
            <xsl:sort select="@num" data-type="number"/>
            <!-- container div for each slide -->
            <div class="slide-item">
                <h1 class="h4">Slide <xsl:value-of select="position()"/></h1>
                <!-- initial template for a slide -->
                <xsl:apply-templates select=".//p:sp | .//p:pic | .//p:graphicFrame"/>
            </div>
        </xsl:for-each>
    </xsl:template>

    <!-- general template for text container -->
    <xsl:template match="p:sp[.//a:r]">
        <xsl:variable name="slide.name" select="ancestor::file/@name"/>
        <xsl:variable name="slide.num">
            <xsl:choose>
                <xsl:when test="contains($slide.name, '/slides/slide') and contains($slide.name, '.xml')">
                    <xsl:value-of select="substring-before(substring-after($slide.name, '/slides/slide'), '.xml')"/>
                </xsl:when>
                <xsl:otherwise>1</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="slide.rels.name" select="concat('_rels/slide', $slide.num, '.xml.rels')"/>
        <xsl:variable name="slide.layout.name">
            <xsl:choose>
                <xsl:when test="$slides.rels[contains(@name, $slide.rels.name)]/*/*/@Target[contains(., 'slideLayouts')]">
                    <xsl:value-of select="substring-after($slides.rels[contains(@name, $slide.rels.name)]/*/*/@Target[contains(., 'slideLayouts')], '../')"/>
                </xsl:when>
                <xsl:otherwise>slideLayout1.xml</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="slide.layout.node" select="$slides.layout[contains(@name, $slide.layout.name)]"/>

        <xsl:variable name="shape.index" select=".//p:ph/@idx"/>
        <xsl:variable name="shape.type" select=".//p:ph/@type"/>

        <!-- check if there are any shape type -->
        <xsl:variable name="isShapeType">
            <xsl:choose>
                <xsl:when test="$shape.type = 'title' or $shape.type = 'ctrTitle'">
                    <xsl:value-of select="$shape.type"/>
                </xsl:when>

                <!-- lists -->
                <xsl:when
                    test="$slide.layout.node//p:sp[.//p:nvPr//p:ph/@idx = $shape.index]//a:p/a:pPr[@lvl]">
                    <xsl:choose>
                        <!-- body with list, but bu:none in entry -->

                        <xsl:when test="$shape.type = 'body' and .//a:buNone">body</xsl:when>
                        <xsl:when
                            test="$slide.layout.node//p:sp[.//p:nvPr//p:ph/@idx = $shape.index]//a:lstStyle/a:lvl1pPr/a:buNone"
                            >body, lvl1 property in slide layout -> bu:none</xsl:when>
                        <xsl:when
                            test="$shape.type = 'body' and (.//a:p/a:pPr[@marL = '0' and @indent = '0'])"
                            >body, indent and marL = 0</xsl:when>
                        <xsl:otherwise>list, in slide layout via index,
                            lvl-attribute</xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>body, no type</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="isShapeIndex">
            <xsl:choose>
                <xsl:when test="$shape.index != ''">
                    <xsl:value-of select="$shape.index"/>
                </xsl:when>
                <xsl:otherwise>NONE</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>


            <!-- class="{$shape.type} -->
            <xsl:if test="$debug = 1">
                <p style="font-size:8pt;color:red;font-weight:bold;">
                    Shape type: <span style="font-weight:normal"><xsl:value-of select="$isShapeType"/></span>
                    <br/>
                    Shape index: <span style="font-weight:normal"><xsl:value-of select="$shape.index"/></span>
                </p>
            </xsl:if>
            <xsl:apply-templates>
                <xsl:with-param name="shape.type" select="$isShapeType"/>
            </xsl:apply-templates>
    </xsl:template>

    <!-- text-style: caption -->
    <xsl:template match="p:sp[.//a:t]">
        <xsl:param name="shape.type"/>
        <xsl:variable name="lvl" select="a:pPr/@lvl"/>
        <p><xsl:value-of select="."/></p>
    </xsl:template>

    <xsl:template match="p:txBody/a:p[a:r]">
        <xsl:param name="shape.type"/>
        <xsl:variable name="lvl" select="a:pPr/@lvl"/>
        <xsl:choose>
            <xsl:when
                test="
                    (starts-with($shape.type, 'list') and
                    not(.//a:buNone)) or
                    .//a:buChar
                    ">

                <!-- all lists are set to unordered lists -->
                <xsl:if test="not(preceding-sibling::a:p)">
                    <xsl:text disable-output-escaping="yes">&lt;ul></xsl:text>
                </xsl:if>

                <xsl:variable name="current.list.level">
                    <xsl:choose>
                        <xsl:when test="not(a:pPr/@lvl)">0</xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="a:pPr/@lvl"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <!-- previous list level -->
                <xsl:variable name="prev.list.level">
                    <xsl:choose>
                        <xsl:when test="not(preceding-sibling::a:p[1]/a:pPr/@lvl)">0</xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="preceding-sibling::a:p[1]/a:pPr/@lvl"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <!-- next list level -->
                <xsl:variable name="next.list.level">
                    <xsl:choose>
                        <xsl:when test="not(following-sibling::a:p[1]/a:pPr/@lvl)">0</xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="following-sibling::a:p[1]/a:pPr/@lvl"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <!-- Python uses the XSLT 1.0 processor
                     - because of that, it's not possible to use the xsl:for-each-group - syntax
                     - via grouping it's easier possible to create a deep structure from a flat one
                     - here we check each list entry (always on the same structure level)
                      - the difference is the lvl-attribute
                      - writing all necessary <ul><li> elements with xsl:text -->

                <xsl:text disable-output-escaping="yes">&lt;li></xsl:text>

                <xsl:apply-templates/>

                <xsl:if test="$next.list.level > $current.list.level">
                    <xsl:text disable-output-escaping="yes">&lt;ul></xsl:text>
                </xsl:if>
                <xsl:if test="$next.list.level &lt; $current.list.level">
                    <xsl:text disable-output-escaping="yes">&lt;/li>&lt;/ul>&lt;/li></xsl:text>
                </xsl:if>
                <xsl:if test="$next.list.level = $current.list.level">
                    <xsl:text disable-output-escaping="yes">&lt;/li></xsl:text>
                </xsl:if>

                <xsl:if test="not(following-sibling::a:p)">
                    <xsl:text disable-output-escaping="yes">&lt;/ul></xsl:text>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates>
                    <xsl:with-param name="shape.type" select="$shape.type"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="a:r">
        <xsl:param name="shape.type"/>

        <xsl:variable name="slide.name" select="ancestor::file/@name"/>
        <xsl:variable name="slide.num">
            <xsl:choose>
                <xsl:when test="contains($slide.name, '/slides/slide') and contains($slide.name, '.xml')">
                    <xsl:value-of select="substring-before(substring-after($slide.name, '/slides/slide'), '.xml')"/>
                </xsl:when>
                <xsl:otherwise>1</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="slide.rels.name" select="concat('_rels/slide', $slide.num, '.xml.rels')"/>
        <xsl:variable name="slide.rels.node" select="$slides.rels[contains(@name, $slide.rels.name)]"/>
        
        <xsl:variable name="slide.layout.name">
            <xsl:choose>
                <xsl:when test="$slide.rels.node/*/*/@Target[contains(., 'slideLayouts')]">
                    <xsl:value-of select="substring-after($slide.rels.node/*/*/@Target[contains(., 'slideLayouts')], '../')"/>
                </xsl:when>
                <xsl:otherwise>slideLayout1.xml</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="slide.layout.node" select="$slides.layout[contains(@name, $slide.layout.name)]"/>

        <xsl:variable name="slide.layout.rels.name">
            <xsl:choose>
                <xsl:when test="$slide.layout.name != ''">
                    <xsl:value-of select="concat('slideLayouts/_rels/slideLayout', substring-before(substring-after($slide.layout.name, '/slideLayout'), '.xml'), '.xml.rels')"/>
                </xsl:when>
                <xsl:otherwise>slideLayouts/_rels/slideLayout1.xml.rels</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="slide.layout.master.name"
            select="substring-after($slides.layout.rels[contains(@name, $slide.layout.rels.name)]/*/*/@Target[contains(., 'slideMasters')], '../')"/>
        <xsl:variable name="slide.layout.master.node"
            select="$slides.master[contains(@name, $slide.layout.master.name)]"/>

        <!-- information from slide layout or slide master -->
        <xsl:variable name="shape.index" select="ancestor::p:sp//p:ph/@idx"/>

        <xsl:variable name="font-weight">
            <xsl:choose>
                <xsl:when test="a:rPr/@b = 1">bold</xsl:when>
                <xsl:when
                    test="$slide.layout.node//p:sp[.//p:nvPr//p:ph/@idx = $shape.index]//p:txBody//a:lvl1pPr/a:defRPr/@b != ''"
                    >bold</xsl:when>
                <xsl:otherwise>normal</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>


        <xsl:variable name="font-style">
            <xsl:choose>
                <xsl:when test="a:rPr/@i = 1">italic</xsl:when>
                <xsl:when
                    test="$slide.layout.node//p:sp[.//p:nvPr//p:ph/@idx = $shape.index]//p:txBody//a:lvl1pPr/a:defRPr/@i != ''"
                    >italic</xsl:when>
                <xsl:otherwise>normal</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- check fo hyperlink -->
        <xsl:variable name="linkId" select="a:rPr/a:hlinkClick/@r:id"/>

        <!-- Additional text properties -->
        <xsl:variable name="text-decoration">
            <xsl:choose>
                <xsl:when test="a:rPr/@u = 'sng'">underline</xsl:when>
                <xsl:when test="a:rPr/@strike = 'sngStrike'">line-through</xsl:when>
                <xsl:otherwise>none</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="vertical-align">
            <xsl:choose>
                <xsl:when test="a:rPr/@baseline = '30000'">super</xsl:when>
                <xsl:when test="a:rPr/@baseline = '-25000'">sub</xsl:when>
                <xsl:otherwise>baseline</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$linkId != ''">
                <a>
                    <xsl:attribute name="href">
                        <xsl:value-of select="$slide.rels.node/*/*[@Id = $linkId]/@Target"/>
                    </xsl:attribute>
                    <span>
                        <xsl:attribute name="style">
                            font-weight: <xsl:value-of select="$font-weight"/>;
                            font-style: <xsl:value-of select="$font-style"/>;
                            text-decoration: <xsl:value-of select="$text-decoration"/>;
                            vertical-align: <xsl:value-of select="$vertical-align"/>;
                            <xsl:if test="a:rPr/@sz">
                                font-size: <xsl:value-of select="a:rPr/@sz div 100"/>pt;
                            </xsl:if>
                            <xsl:if test="a:rPr/a:solidFill/a:srgbClr/@val">
                                color: #<xsl:value-of select="a:rPr/a:solidFill/a:srgbClr/@val"/>;
                            </xsl:if>
                        </xsl:attribute>
                        <xsl:apply-templates/>
                    </span>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <span>
                    <xsl:attribute name="style">
                        font-weight: <xsl:value-of select="$font-weight"/>;
                        font-style: <xsl:value-of select="$font-style"/>;
                        text-decoration: <xsl:value-of select="$text-decoration"/>;
                        vertical-align: <xsl:value-of select="$vertical-align"/>;
                        <xsl:if test="a:rPr/@sz">
                            font-size: <xsl:value-of select="a:rPr/@sz div 100"/>pt;
                        </xsl:if>
                        <xsl:if test="a:rPr/a:solidFill/a:srgbClr/@val">
                            color: #<xsl:value-of select="a:rPr/a:solidFill/a:srgbClr/@val"/>;
                        </xsl:if>
                    </xsl:attribute>
                    <xsl:apply-templates/>
                </span>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="a:br">
        <br />
    </xsl:template>

    <xsl:template match="p:graphicFrame">
        <xsl:apply-templates select=".//a:tbl"/>
    </xsl:template>

    <!-- tables -->
    <xsl:template match="a:tbl">
        <h3>Table</h3>
        <table class="table">
            <xsl:apply-templates select="a:tr"/>
        </table>
    </xsl:template>

    <!-- table rows -->
    <xsl:template match="a:tr">
        <tr>
            <!-- if a firstRow attribute available, the first row (header) looks a little bit different -->
            <xsl:if test="not(preceding-sibling::a:tr) and parent::a:tbl/a:tblPr/@firstRow = '1'">
                <xsl:attribute name="class">tableRowFirst</xsl:attribute>
            </xsl:if>
            <xsl:apply-templates/>
        </tr>
    </xsl:template>

    <!-- table cells -->
    <xsl:template match="a:tc">
        <td>
            <xsl:if test="@rowSpan">
                <xsl:attribute name="rowspan">
                    <xsl:value-of select="@rowSpan"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:if test="@gridSpan">
                <xsl:attribute name="colspan">
                    <xsl:value-of select="@gridSpan"/>
                </xsl:attribute>
            </xsl:if>
            <xsl:if test=".//a:tcBdr">
                <xsl:attribute name="style">
                    border: 1px solid #000;
                </xsl:attribute>
            </xsl:if>
            <xsl:apply-templates select=".//a:p"/>
        </td>
    </xsl:template>

    <!-- Text in table cells -->
    <xsl:template match="a:p[ancestor::a:tc]">
        <xsl:value-of select=".//a:t"/>
        <xsl:if test="following-sibling::a:p">
            <br/>
        </xsl:if>
    </xsl:template>

    <!-- Skip span formatting inside tables -->
    <xsl:template match="a:r[ancestor::a:tc]">
        <xsl:value-of select=".//a:t"/>
    </xsl:template>

    <!-- Images -->
    <xsl:template match="p:pic">
        <xsl:variable name="slide.name" select="ancestor::file/@name"/>
        <xsl:variable name="slide.num"
            select="substring-before(substring-after($slide.name, '/slides/slide'), '.xml')"/>
        <xsl:variable name="slide.rels.name" select="concat('_rels/slide', $slide.num, '.xml.rels')"/>
        <xsl:variable name="slide.layout.name"
            select="substring-after($slides.rels[contains(@name, $slide.rels.name)]/*/*/@Target, '../')"/>
        <xsl:variable name="slide.layout.node"
            select="$slides.layout[contains(@name, $slide.layout.name)]"/>

        <xsl:variable name="slide.rels.node"
            select="$slides.rels[contains(@name, $slide.rels.name)]"/>

        <!-- id for image in rels file -->
        <xsl:variable name="id" select="descendant::a:blip/@r:embed"/>

        <!-- image filename and description -->
        <div class="image-object">
            <p><strong>Image: </strong>
                <xsl:text> </xsl:text>
                <xsl:value-of
                    select="$slide.rels.node//*[name() = 'Relationship'][@Id = $id]/@Target"/>
                <br />
                <span class="text-muted"><strong>Description: </strong>
                <xsl:value-of select="p:nvPicPr/p:cNvPr/@descr"/></span>
            </p>
        </div>
    </xsl:template>

    <!-- SmartArt Graphics -->
    <xsl:template match="p:graphicFrame[.//a:graphic]">
        <div class="smartart">
            <xsl:apply-templates select=".//a:graphicData/*"/>
        </div>
    </xsl:template>

    <!-- Charts -->
    <xsl:template match="p:graphicFrame[.//c:chart]">
        <div class="chart">
            <p><strong>Chart</strong></p>
            <xsl:variable name="chartId" select=".//c:chart/@r:id"/>
            <xsl:if test="$chartId">
                <p class="chart-ref">Chart Reference: <xsl:value-of select="$chartId"/></p>
            </xsl:if>
        </div>
    </xsl:template>

    <!-- Slide background -->
    <xsl:template match="p:bg">
        <div class="slide-background">
            <xsl:choose>
                <xsl:when test=".//a:solidFill">
                    <xsl:attribute name="style">
                        background-color: #<xsl:value-of select=".//a:srgbClr/@val"/>;
                    </xsl:attribute>
                </xsl:when>
                <xsl:when test=".//a:blipFill">
                    <!-- Handle background image -->
                    <xsl:variable name="bgImageId" select=".//a:blip/@r:embed"/>
                    <xsl:attribute name="style">
                        background-image: url('<xsl:value-of select="$slide.rels.node//*[@Id = $bgImageId]/@Target"/>');
                    </xsl:attribute>
                </xsl:when>
            </xsl:choose>
        </div>
    </xsl:template>

    <!-- Media elements -->
    <xsl:template match="p:video">
        <div class="video-object">
            <p><strong>Video: </strong>
                <xsl:value-of select="@name"/>
                <xsl:if test="p:nvPicPr/p:cNvPr/@descr">
                    <br/>
                    <span class="text-muted"><strong>Description: </strong>
                        <xsl:value-of select="p:nvPicPr/p:cNvPr/@descr"/>
                    </span>
                </xsl:if>
            </p>
        </div>
    </xsl:template>

    <xsl:template match="p:audio">
        <div class="audio-object">
            <p><strong>Audio: </strong>
                <xsl:value-of select="@name"/>
                <xsl:if test="p:nvPicPr/p:cNvPr/@descr">
                    <br/>
                    <span class="text-muted"><strong>Description: </strong>
                        <xsl:value-of select="p:nvPicPr/p:cNvPr/@descr"/>
                    </span>
                </xsl:if>
            </p>
        </div>
    </xsl:template>

    <!-- Math equations - simplified version -->
    <xsl:template match="m:oMath">
        <div class="equation">
            <p class="math-content">
                <xsl:value-of select="."/>
            </p>
        </div>
    </xsl:template>

    <!-- Group shapes -->
    <xsl:template match="p:grpSp">
        <div class="shape-group">
            <xsl:apply-templates select="p:sp | p:pic | p:graphicFrame | p:grpSp"/>
        </div>
    </xsl:template>

    <!-- Connectors and lines -->
    <xsl:template match="p:cxnSp">
        <div class="connector">
            <xsl:if test="p:nvCxnSpPr/p:cNvPr/@name">
                <p class="connector-name">
                    <xsl:value-of select="p:nvCxnSpPr/p:cNvPr/@name"/>
                </p>
            </xsl:if>
        </div>
    </xsl:template>

    <!-- Slide notes -->
    <xsl:template match="p:notes">
        <div class="slide-notes">
            <h4>Slide Notes</h4>
            <xsl:apply-templates select=".//p:sp[.//a:r]"/>
        </div>
    </xsl:template>

    <!-- Animations -->
    <xsl:template match="p:timing">
        <div class="animations">
            <xsl:for-each select=".//p:anim | .//p:animEffect | .//p:animMotion">
                <div class="animation-effect">
                    <xsl:attribute name="data-effect">
                        <xsl:value-of select="@type"/>
                    </xsl:attribute>
                    <xsl:attribute name="data-duration">
                        <xsl:value-of select="@dur"/>
                    </xsl:attribute>
                </div>
            </xsl:for-each>
        </div>
    </xsl:template>

    <!-- Slide transitions -->
    <xsl:template match="p:transition">
        <div class="slide-transition">
            <xsl:attribute name="data-transition-type">
                <xsl:value-of select="@type"/>
            </xsl:attribute>
            <xsl:attribute name="data-duration">
                <xsl:value-of select="@dur"/>
            </xsl:attribute>
        </div>
    </xsl:template>

    <!-- WordArt -->
    <xsl:template match="a:prstTxWarp">
        <div class="wordart">
            <xsl:attribute name="data-wordart-style">
                <xsl:value-of select="@prst"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <!-- Text effects -->
    <xsl:template match="a:effectLst">
        <xsl:attribute name="style">
            <xsl:if test="a:glow">
                text-shadow: 0 0 <xsl:value-of select="a:glow/@rad"/>px 
                    #<xsl:value-of select="a:glow//a:srgbClr/@val"/>;
            </xsl:if>
            <xsl:if test="a:outerShdw">
                box-shadow: <xsl:value-of select="a:outerShdw/@dx"/>px 
                    <xsl:value-of select="a:outerShdw/@dy"/>px 
                    <xsl:value-of select="a:outerShdw/@blurRad"/>px 
                    #<xsl:value-of select="a:outerShdw//a:srgbClr/@val"/>;
            </xsl:if>
            <xsl:if test="a:reflection">
                -webkit-box-reflect: below 0
                    linear-gradient(transparent, rgba(0,0,0,<xsl:value-of select="a:reflection/@stA"/>));
            </xsl:if>
        </xsl:attribute>
    </xsl:template>

    <!-- Custom shapes -->
    <xsl:template match="p:sp[.//a:custGeom]">
        <div class="custom-shape">
            <xsl:attribute name="data-path">
                <xsl:value-of select=".//a:path/@w"/>
                <xsl:text>,</xsl:text>
                <xsl:value-of select=".//a:path/@h"/>
            </xsl:attribute>
            <xsl:apply-templates select=".//a:moveTo | .//a:lnTo | .//a:arcTo | .//a:quadBezTo | .//a:cubicBezTo"/>
        </div>
    </xsl:template>

    <!-- Theme colors -->
    <xsl:template match="a:theme">
        <xsl:variable name="theme-colors">
            <xsl:for-each select=".//a:clrScheme/*">
                <xsl:value-of select="name()"/>
                <xsl:text>:</xsl:text>
                <xsl:value-of select=".//a:srgbClr/@val"/>
                <xsl:text>;</xsl:text>
            </xsl:for-each>
        </xsl:variable>
        <div class="theme-colors" style="display:none;">
            <xsl:value-of select="$theme-colors"/>
        </div>
    </xsl:template>
</xsl:stylesheet>
