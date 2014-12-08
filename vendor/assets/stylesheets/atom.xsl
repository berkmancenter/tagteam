<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0"
  xmlns:atom="http://www.w3.org/2005/Atom"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html"/>

  <!-- supress default text node output -->
  <xsl:template match="text()"/>

  <xsl:template match="/atom:feed/atom:entry">
    <h2 class="title">
      <a href="{atom:link/@href}">
        <xsl:value-of select="atom:title" disable-output-escaping="yes"/>
      </a>
    </h2>
    <div class="date">
      <xsl:value-of select="substring(atom:updated, 0, 11)"/>
    </div>
    <div>
      <xsl:value-of select="atom:summary" disable-output-escaping="yes"/>
    </div>
  </xsl:template>
</xsl:stylesheet>
