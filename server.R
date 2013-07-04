library(shiny)

# Load in the sampled matrix we've generated ahead of time.
tumor <- readRDS("tumorExpr.Rds")
normal <- readRDS("normalExpr.Rds")

shinyServer(function(input, output) {
  # Expression that generates a plot of the distribution. The expression
  # is wrapped in a call to renderPlot to indicate that:
  #
  #  1) It is "reactive" and therefore should be automatically
  #     re-executed when inputs change
  #  2) Its output type is a plot
  #
  output$genePlot <- renderPlot({
    
    #Extract the relevant tumor and normal expression values.
    tumorGene <- tumor[rownames(tumor) == input$gene, ]
    normalGene <- normal[rownames(normal) == input$gene, ]
    
    #Format as a list and plot as a boxplot
    expr <- list(Tumor=tumorGene, Normal=normalGene)
    boxplot(expr, main=input$gene)
  })
})