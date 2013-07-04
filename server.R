library(shiny)
library(Biobase)
library(survival)

# Load in the sampled matrices we've generated ahead of time.
tumor <- readRDS("tumorExpr.Rds")
# Distill the expression data away from the ExpressionSet object.
tumorExp <- exprs(tumor)

shinyServer(function(input, output, session) {
  
  #' Extract the relevant tumor expression values.
  geneExp <- reactive({
    geneExp <- tumorExp[rownames(tumorExp) == input$gene, ]
    
    # Update the slider to have a reasonable starting value.
    updateSliderInput(session, "cutoff", value=median(geneExp))
    
    geneExp
  })
  
  #' Render a plot to show the distribution of the gene's expression
  output$densityPlot <- renderPlot({
    # Set the bg color to match the sidebar.
    par(bg = "#F5F5F5")
    
    # Plot to density plot
    tumorGene <- geneExp()
    plot(density(tumorGene), main="Distribution", xlab="")
    
    # Add a vertical line to show where the current cutoff is.
    abline(v=input$cutoff, col=4)
  })
  
  #' A reactive survival formula
  survivalFml <- reactive({
    tumorGene <- geneExp()
    
    # Create the groups based on which samples are above/below the cutoff
    expressionGrp <- as.integer(tumorGene < input$cutoff)
    
    # Make sure there's more than one group!
    if (length(unique(expressionGrp)) < 2){
      stop("You must specify a cutoff that places at least one sample in each group!")
    }
    
    # Create the survival object
    surv <- with(pData(tumor), 
                 Surv(days_to_death, recurrence_status=="recurrence"))
    return(surv ~ expressionGrp)
  })
  
  #' Print out some information about the fit
  output$info <- renderPrint({
    surv <- survivalFml()
    sDiff <- survdiff(surv)
    
    # Calculate the p value
    # Extracted from the print.survdiff function in the survival package
    df <- (sum(1 * (sDiff$exp > 0))) - 1
    pv <- format(signif(1 - pchisq(sDiff$chisq, df), 2))
    
    cat ("p-value: ", pv, "\n")
  })
  
  #' Create a Kaplan Meier plot
  output$kmPlot <- renderPlot({
    surv <- survivalFml()
    plot(survfit(surv), col=1:2)
    legend(10,.4,c("Low Expr", "High Expr"), lty=1, col=1:2)
  })
})
