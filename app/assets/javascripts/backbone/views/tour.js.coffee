class Tours.Views.GuidedTour extends Backbone.View
  template : JST['backbone/templates/tour']

  el: '#tour'

  events:
    'mouseover .viewDefault' : 'showEditButton'
    'mouseout .viewDefault' : 'hideEditButton'
    'click .tourShowEdit' : 'showEdit'
    'click .tourAddPage' : 'showAddPage'
    'click .tourAddSection' : 'showAddSection'
    'click .tourRemovePage' : 'removePage'
    'click .tourRemoveSection' : 'removeSection'
    'click .tourSave' : 'updateTour'
    'click. #start' : 'start'
    #'click .tour' : 'updateTour'

  initialize: ->
    self = @
    @model = new Tours.Models.Tour(title: Tours.tourTitle)
    @model.fetch(success: (model) ->
      self.render()
    )

  isAdmin: ->
    _.contains(Wiki.currentUser.get('actions'), "Edit")

  render: ->
    html = @template(title: @model.get('title'), author: @model.get('author'), pages: @model.get('pages'))
    $(@el).html(html)
    minHeight = 40

    if (@isAdmin())
      $('#pages').sortable({
        items: '.page',
        cursor: 'move',
        axis: 'y',
        tolerance: 'pointer',
        delay: 150 ,
        toleranceElement: '> div',
        placeholder: "sortable-placeholder",
        forcePlaceholderSize: true,
        start: (event, ui) ->
          height = ui.item.height() / 2
          if (height < minHeight)
            height = minHeight
          $('.sortable-placeholder').css('height', height)
      })
      $('.sections').sortable({
        items: ' .section',
        containment: 'parent',
        cursor: 'move',
        axis: 'y',
        tolerance: 'pointer',
        delay: 150 ,
        toleranceElement: '> div'
      })
      $('.tourMove').disableSelection()



  getTriggerButton: (triggerEvent) ->
    triggerButton = triggerEvent.target
    while (triggerButton.tagName != 'BUTTON')
      #console.log(triggerElement.tagName)
      triggerButton = triggerButton.parentNode
    triggerButton

  getTriggerByClass: (triggerEvent, className) ->
    triggerButton = triggerEvent.target
    while (triggerButton.className != className)
      #console.log(triggerElement.tagName)
      triggerButton = triggerButton.parentNode
    triggerButton

  showEditButton: (triggerEvent) ->
    triggerElement = @.getTriggerByClass(triggerEvent, 'viewDefault')
    #console.log(triggerElement)
    editButtons = $(triggerElement).find('.editButtons')
    #console.log(editButton)
    $(editButtons).css('display', 'inline')

  hideEditButton: (triggerEvent) ->
    triggerElement = @.getTriggerByClass(triggerEvent, 'viewDefault')
    editButtons = $(triggerElement).find('.editButtons')
    $(editButtons).css('display', 'none')

  showEdit: (triggerEvent) ->
    triggerElement = @.getTriggerButton(triggerEvent)

    parent = triggerElement.parentNode.parentNode.parentNode
    #console.log(parent)

    defaultBoxes = parent.getElementsByClassName('viewDefault')
    #console.log(defaultBoxes)
    for defaultBox in defaultBoxes
      try
        #console.log(defaultBox)
        defaultBox.style.display = 'none'
      catch error
        console.log(error)

    editBoxes = parent.getElementsByClassName('viewEdit')
    #console.log(editBoxes)
    for position, editBox of editBoxes
      try
        #console.log(editBox)
        editBox.style.display = 'block'
      catch error
        console.log(error)

  showAddPage: ->
    pageList = $.find('#pages')
    $(pageList).append(
      '<li class="page">\n'+
      ' <hr>\n'+
      ' <div class="pageItem">\n'+
      '  <button class="btn btn-small tourAddSection" type="button"><i class="icon-plus"></i> Add Section</button>\n'+
      '  <div class="viewDefault">'+
      '   <a class="titleLink" href="/wiki/newPage">new Page</a>\n'+
      '   <span class="editButtons">\n' +
      '    <button class="btn-mini tourShowEdit" type="button"><i class="icon-pencil"></i></button><button class="btn-mini tourRemovePage" type="button"><i class="icon-remove"></i></button>\n'+
      '    <i class="icon-move tourMove"></i>\n'+
      '   </span>\n'+
      '  </div>\n'+
      '  <div class="viewEdit"><input class="pageTitle" value="new Page"></div>\n'+
      ' </div>\n'+
      ' <ul class="sections">\n'+
      '  <li class="section">\n'+
      '   <div class="sectionItem">\n'+
      '    <div class="viewDefault">\n'+
      '     <a class="sectionLink" href="/wiki/newPage#Section">#Section</a>\n'+
      '     <span class="editButtons">\n' +
      '      <button class="btn-mini tourShowEdit" type="button"><i class="icon-pencil"></i></button><button class="btn-mini tourRemoveSection" type="button"><i class="icon-remove"></i></button>\n'+
      '      <i class="icon-move tourMove"></i>\n'+
      '     </span>\n'+
      '     <p class="sectionDescriptionText">\n'+
      '      Description...\n'+
      '     </p>\n'+
      '    </div>\n'+
      '    <div class="viewEdit">\n'+
      '     <input class="sectionTitle" value="Section">\n'+
      '     <p>\n'+
      '      <textarea class="sectionDescription" cols="50" rows="3">Description</textarea>\n'+
      '     </p>\n'+
      '    </div>\n'+
      '  </div>\n'+
      '  </li>\n'+
      ' </ul>\n'+
      '</li>\n'
    )

  showAddSection: (triggerEvent) ->
    triggerElement = @.getTriggerByClass(triggerEvent, 'page')
    sectionsList = $(triggerElement).find('.sections')
    #console.log(sectionsList)
    $(sectionsList).append(
      '  <li class="section">\n'+
      '   <div class="sectionItem">\n'+
      '    <div class="viewDefault">\n'+
      '     <a class="sectionLink" href="/wiki/newPage#Section">#Section</a>\n'+
      '     <span class="editButtons">\n' +
      '      <button class="btn-mini tourShowEdit" type="button"><i class="icon-pencil"></i></button><button class="btn-mini tourRemoveSection" type="button"><i class="icon-remove"></i></button>\n'+
      '      <i class="icon-move tourMove"></i>\n'+
      '     </span>\n'+
      '     <p class="sectionDescriptionText">\n'+
      '      Description...\n'+
      '     </p>\n'+
      '    </div>\n'+
      '    <div class="viewEdit">\n'+
      '     <input class="sectionTitle" value="Section">\n'+
      '     <p>\n'+
      '      <textarea class="sectionDescription" cols="50" rows="3">Description</textarea>\n'+
      '     </p>\n'+
      '    </div>\n'+
      '  </div>\n'+
      '  </li>\n'
    )

  removePage: (triggerEvent) ->
    triggerElement = @.getTriggerByClass(triggerEvent, 'page')
    $(triggerElement).remove()

  removeSection: (triggerEvent) ->
    triggerElement = @.getTriggerByClass(triggerEvent, 'section')
    $(triggerElement).remove()

  updateTour: (triggerEvent) ->
    authorElement = $.find(".author")[0]
    authorEditView = $(authorElement).find('.viewEdit')[0]
    author = Wiki.currentUser.id
    authorDefaultView = $(authorElement).find('.viewDefault')[0]
    authorLink = $(authorDefaultView).find('a')[0]
    $(authorLink).text(author)
    $(authorLink).attr('href', 'https://github.com/'+author+'/')
    #console.log(author)

    tourElement = $.find("#tour")[0]
    pageList = $(tourElement).find("#pages")[0]
    pageItems = $(pageList).find(".page")
    pages = []
    i = 0

    for pageItem in $(pageItems)
      pageTitle = $(pageItem).find(".pageTitle")[0].value
      console.log(pageTitle)
      pageTitleLink = $(pageItem).find(".titleLink")[0]
      #console.log($(pageTitleLink))
      $(pageTitleLink).attr('href', '/wiki/'+pageTitle);
      $(pageTitleLink).text(pageTitle);
      sectionList =  $(pageItem).find(".sections")[0]
      sectionItems = $(sectionList).find(".section")
      sections = []
      j = 0

      for sectionItem in $(sectionItems)
        sectionTitle = $(sectionItem).find(".sectionTitle")[0].value
        sectionLink = $(sectionItem).find(".sectionLink")[0]
        $(sectionLink).attr('href', '/wiki/'+pageTitle+'#'+sectionTitle);
        $(sectionLink).text('#'+sectionTitle);
        
        sectionDescription = $(sectionItem).find(".sectionDescription")[0].val()
        sectionDescriptionText = $(sectionItem).find(".sectionDescriptionText")[0].val();
        $(sectionDescriptionText).text(sectionDescription);
        
        sections[j++] = new Tours.Models.TourSection(
          title: sectionTitle
          desription: sectionDescription 
        )

      pages[i++] = new Tours.Models.TourPage(
        title: pageTitle
        sections: sections
      )

    @model.save(
      {
        author: author
        pages: pages
      }
      success: ->
        console.log(@model)

        $(authorEditView).css('display', 'none')
        $(authorDefaultView).css('display', 'block')

        for pageItem in $(pageItems)
          editViews = $(pageItem).find('.viewEdit')
          #console.log(editViews)

          for editView in $(editViews)
            console.log($(editView))
            $(editView).css('display', 'none')

          defaultViews = $(pageItem).find('.viewDefault')
          for defaultView in $(defaultViews)
            $(defaultView).css('display', 'block')
    )


  start: ->
    if @model.get('pages')
      localStorage.setItem('currentTour', JSON.stringify(@model.toJSON()))
      localStorage.setItem('currentTourStep', 0)
      window.location = '/wiki/' + @model.get('pages')[0].title

