module FirstTimeDataGenerator

  # Create data for tutorial for new users
  def seed_demo_data user
    @user = user

    # First organization that this user created
    # should contain the "intro" project
    if cookies[:repeat_tutorial_org_id]
      org = Organization.find(cookies[:repeat_tutorial_org_id])
      cookies.delete :repeat_tutorial_org_id
    else
      org = user
        .organizations
        .where(created_by: user)
        .order(created_at: :asc)
        .first
    end

    # If private private organization does not exist,
    # there was something wrong with user creation.
    # Do nothing
    return unless org

    # Create sample types
    SampleType.create(
      name: "Potato leaves",
      organization: org
    )

    SampleType.create(
      name: "Tea leaves",
      organization: org
    )

    SampleType.create(
      name: "Potato bug",
      organization: org
    )

    SampleGroup.create(
      name: "Fodder",
      organization: org,
      color: "#159B5E"
    )

    SampleGroup.create(
      name: "Nutrient",
      organization: org,
      color: "#6C159E"
    )

    SampleGroup.create(
      name: "Seed",
      organization: org,
      color: "#FF4500"
    )

    samples = []
    # Generate random sample names start
    # and put it on the beginning of 5 samples
    sample_name = (0...3).map{65.+(rand(26)).chr}.join << '/'
    for i in 1..5
      samples << Sample.create(
        name: sample_name + i.to_s,
        organization: org,
        user: user,
        sample_type: rand < 0.8 ? pluck_random(org.sample_types) : nil,
        sample_group: rand < 0.8 ? pluck_random(org.sample_groups) : nil
      )
    end

    sample_name = (0...3).map{65.+(rand(26)).chr}.join << '/'
    for i in 1..5
      samples << Sample.create(
        name: sample_name + i.to_s,
        organization: org,
        user: user,
        sample_type: rand < 0.8 ? pluck_random(org.sample_types) : nil,
        sample_group: rand < 0.8 ? pluck_random(org.sample_groups) : nil
      )
    end

    name = "Demo project - qPCR"
    exp_name = "My first experiment"
    # If there is an existing demo project, archive and rename it
    if org.projects.where(name: name).present?
      old = org.projects.where(name: "Demo project - qPCR")[0]
      # old.archive! user
      i = 1
      while org.projects.where(name: name = "Demo project - qPCR (#{i})").present?
        i += 1
      end
    end

    project = Project.create(
      visibility: 0,
      name: name,
      due_date: nil,
      organization: org,
      created_by: user,
      created_at: generate_random_time(1.week.ago),
      last_modified_by: user,
      archived: false
    )

    experiment = Experiment.create(
      name: exp_name,
      description: "This is my very first experiment",
      project: project,
      created_by: user,
      created_at: project.created_at + 5.minutes,
      last_modified_by: user
    )

    # Automatically assign project author onto project
    UserProject.create(
      user: user,
      project: project,
      role: 0,
      created_at: generate_random_time(1.week.ago)
    )

    # Activity for creating project
    Activity.create(
      type_of: :create_project,
      user: user,
      project: project,
      message: I18n.t(
        "activities.create_project",
        user: user.full_name,
        project: project.name
      ),
      created_at: project.created_at
    )

    # Add a comment
    generate_project_comment(
      project,
      user,
      "I've created a demo project"
    )

    # Create a module group
    my_module_group = MyModuleGroup.create(
      name: "Potato qPCR workflow",
      experiment: experiment
    )

    # Create project modules
    my_modules = []
    my_module_names = [
      "Experiment design",
      "Sampling biological material",
      "RNA isolation",
      "RNA quality & quantity - BIOANALYSER",
      "Reverse transcription",
      "qPCR",
      "Data quality control",
      "Data analysis - ddCq"
    ]

    qpcr_module_description = "PCR is a method where an enzyme
      (thermostable DNA polymerase, originally isolated in 1960s
      from bacterium Thermus aquaticus, growing in hot lakes of
      Yellowstone park, USA) amplifies a short specific part of
      the template DNA (amplicon) in cycles. In every cycle the
      number of short specific sections of DNA is doubled, leading
      to an exponential amplification of targets. More on how
      conventional PCR works can be found here."

    my_module_names.each_with_index do |name, i|
      my_module = MyModule.create(
        name: name,
        created_by: user,
        created_at: generate_random_time(6.days.ago),
        due_date: Time.now + (2 * i + 1).weeks,
        description: i == 5 ? qpcr_module_description : nil,
        x: (i < 4 ? i % 4 : 7 - i) * 32,
        y: (i / 4) * 16,
        experiment: experiment,
        workflow_order: i,
        my_module_group: my_module_group
      )

      my_modules << my_module

      # Add connections between current and previous module
      if i > 0
        Connection.create(
          input_id: my_module.id,
          output_id: my_modules[i-1].id
        )
      end

      # Create module activity
      Activity.create(
        type_of: :create_module,
        user: user,
        project: project,
        my_module: my_module,
        message: I18n.t(
          "activities.create_module",
          user: user.full_name,
          module: my_module.name
        ),
        created_at: my_module.created_at
      )

      UserMyModule.create(
        user: user,
        my_module: my_module,
        assigned_by: user,
        created_at: generate_random_time(my_module.created_at, 2.minutes)
      )
      Activity.create(
        type_of: :assign_user_to_module,
        user: user,
        project: project,
        my_module: my_module,
        message: I18n.t(
          "activities.assign_user_to_module",
          assigned_user: user.full_name,
          module: my_module.name,
            assigned_by_user: user.full_name
        ),
        created_at: generate_random_time(my_module.created_at, 2.minutes)
      )
    end

    # Create an archived module
    archived_module = MyModule.create(
      name: "Data analysis - Pfaffl method",
      created_by: user,
      created_at: generate_random_time(6.days.ago),
      due_date: Time.now + 1.week,
      description: nil,
      x: -1,
      y: -1,
      experiment: experiment,
      workflow_order: -1,
      my_module_group: nil,
      archived: true,
      archived_on: generate_random_time(3.days.ago),
      archived_by: user
    )

    # Activity for creating archived module
    Activity.create(
      type_of: :create_module,
      user: user,
      project: project,
      my_module: archived_module,
      message: I18n.t(
        "activities.create_module",
        user: user.full_name,
        module: archived_module.name
      ),
      created_at: archived_module.created_at
    )

    # Activity for archiving archived module
    Activity.create(
      type_of: :archive_module,
      user: user,
      project: project,
      my_module: archived_module,
      message: I18n.t(
        "activities.archive_module",
        user: user.full_name,
        module: archived_module.name
      ),
      created_at: archived_module.archived_on
    )

    # Assign new user to archived module
    UserMyModule.create(
      user: user,
      my_module: archived_module,
      assigned_by: user,
      created_at: generate_random_time(archived_module.created_at, 2.minutes)
    )
    Activity.create(
      type_of: :assign_user_to_module,
      user: user,
      project: project,
      my_module: archived_module,
      message: I18n.t(
        "activities.assign_user_to_module",
        assigned_user: user.full_name,
        module: archived_module.name,
          assigned_by_user: user.full_name
      ),
      created_at: generate_random_time(archived_module.created_at, 2.minutes)
    )

    # Assign 4 samples to modules
    samples_to_assign = []
    taken_sample_ids = []
    for _ in 1..4
      begin
        sample = samples.sample
      end while sample.id.in? taken_sample_ids
      taken_sample_ids << sample.id
      samples_to_assign << sample
    end


    my_modules[1].get_downstream_modules.each do |mm|
      samples_to_assign.each do |s|
        SampleMyModule.create(
          sample: s,
          my_module: mm
        )
      end
    end

    # Add comments to modules
    generate_module_comment(
      my_modules[0],
      user,
      'We should have a meeting to discuss sampling parametrs soon.'
    )
    generate_module_comment(
      my_modules[0],
      user,
      'I agree.'
    )

    generate_module_comment(
      my_modules[1],
      user,
      'The samples have arrived.'
    )

    generate_module_comment(
      my_modules[2],
      user,
      'Due date has been postponed for a day.'
    )

    generate_module_comment(
      my_modules[4],
      user,
      'Please show Steve the RT procedure.'
    )

    generate_module_comment(
      my_modules[5],
      user,
      'The results must be very definitive.'
    )

    generate_module_comment(
      my_modules[7],
      user,
      'The due date here is flexible.'
    )

    # Create tags and add them to module
    drylab_tag = Tag.create(
      name: "Drylab",
      color: "#15369E",
      project: project,
      created_by: user,
      last_modified_by: user
    )
    wetlab_tag = Tag.create(
      name: "Wetlab",
      color: "#FF8C00",
      project: project,
      created_by: user,
      last_modified_by: user
    )
    decide_tag = Tag.create(
      name: "Decide",
      color: "#32CD32",
      project: project,
      created_by: user,
      last_modified_by: user
    )

    # Add tags to module
    my_modules[0].tags << drylab_tag

    my_modules[1].tags << wetlab_tag
    my_modules[2].tags << wetlab_tag
    my_modules[3].tags << wetlab_tag
    my_modules[4].tags << wetlab_tag

    my_modules[5].tags << drylab_tag
    my_modules[6].tags << drylab_tag

    my_modules[7].tags << drylab_tag
    my_modules[7].tags << decide_tag
    my_modules[7].save

    # Load table contents yaml file
    tab_content = YAML.load_file("#{Rails.root}/app/assets/tutorial_files/tables_content.yaml")

    # Create module content
    # ----------------- Module 1 ------------------
    module_step_names = [
      "Gene expression"
    ]
    module_step_descriptions = [
      "Compare response of PVYNTN, cab4 and PR1 genes in mock/virus inoculated potatoes & in time"
    ]
    generate_module_steps(my_modules[0], module_step_names, module_step_descriptions)

    # Results
    DelayedUploaderTutorial.delay(queue: :tutorial).generate_result_asset(
      my_module: my_modules[0],
      current_user: user,
      result_name: "sF",
      created_at: generate_random_time(my_modules[0].created_at, 2.days),
      file_name: "samples.txt"
    )

    temp_result = Result.new(
      name: "Experimental design",
      my_module: my_modules[0],
      created_at: generate_random_time(my_modules[0].created_at, 1.days),
      user: user
    )
    generate_result_comment(
      temp_result,
      user,
      'The table shows proposed number of biological replicates.'
    )
    temp_result.table = Table.new(
      created_by: user,
      contents: tab_content["module1"]["experimental_design"]
    )
    temp_result.save

    # ----------------- Module 2 ------------------
    module_step_names = [
      "Inoculation of potatoes",
      "Collection of potatoes",
      "Store samples"
    ]
    module_step_descriptions = [
      "50% of samples should be mock inoculated while other 50% with PVY NTN virus.",
      "50% of PVYNTN inoculated potatos and 50% of Mock inoculated potatos collect 1 day post inocullation while other halph of samples collect 6 days post inoculation.",
      "Collect samples in 2ml tubes and put them in liquid nitrogen and store at 80°C."
    ]
    generate_module_steps(my_modules[1], module_step_names, module_step_descriptions)

    # Add file to existig step
    DelayedUploaderTutorial.delay(queue: :tutorial).add_step_asset(
      step: my_modules[1].protocol.steps.where("position = 0").take,
      current_user: user,
      file_name: "sample-potatoe.txt"
    )

    # Results
    DelayedUploaderTutorial.delay(queue: :tutorial).generate_result_asset(
      my_module: my_modules[1],
      current_user: user,
      result_name: "PVY-inoculated plant, symptoms",
      created_at: generate_random_time(my_modules[1].created_at, 1.days),
      file_name: "DSCN0660.JPG"
    )

    DelayedUploaderTutorial.delay(queue: :tutorial).generate_result_asset(
      my_module: my_modules[1],
      current_user: user,
      result_name: "mock-inoculated plant",
      created_at: generate_random_time(my_modules[1].created_at, 2.days),
      file_name: "DSCN0354.JPG"
    )

    DelayedUploaderTutorial.delay(queue: :tutorial).generate_result_asset(
      my_module: my_modules[1],
      current_user: user,
      result_name: "Height of plants at 6dpi",
      created_at: generate_random_time(my_modules[1].created_at, 3.days),
      file_name: "6dpi_height.JPG"
    )

    # Add a text result
    temp_result = Result.new(
      name: "Number of samples",
      my_module: my_modules[1],
      user: user,
      created_at: generate_random_time(my_modules[1].created_at, 4.days)
    )
    temp_text = "There are many biological replicates we harvested for each type of sample (code-names):\n\n"
    samples_to_assign.each do |s|
      temp_text << "* #{s.name}\n\n"
    end
    temp_result.result_text = ResultText.new(
      text: temp_text
    )

    temp_result.save

    # Create result activity
    Activity.create(
      type_of: :add_result,
      project: project,
      my_module: my_modules[1],
      user: user,
      created_at: temp_result.created_at,
      message: I18n.t(
        "activities.add_text_result",
        user: user.full_name,
        result: temp_result.name
      )
    )
    # ----------------- Module 3 ------------------
    module_step_names = [
      "Homogenization of the material",
      "Isolation of RNA with RNeasy plant mini kit"
    ]
    module_step_descriptions = [
      " Use tissue lyser: 1 min on step 3.",
      nil
    ]
    generate_module_steps(my_modules[2], module_step_names, module_step_descriptions)

    # Add file to existig step
    DelayedUploaderTutorial.delay(queue: :tutorial).add_step_asset(
      step: my_modules[2].protocol.steps.where("position = 1").take,
      current_user: user,
      file_name: "RNeasy-Plant-Mini-Kit-EN.pdf"
    )

    # Results
    temp_result = Result.new(
      name: "Nanodrop results",
      my_module: my_modules[2],
      created_at: generate_random_time(my_modules[2].created_at, 1.days),
      user: user
    )
    generate_result_comment(
      temp_result,
      user,
      'PVY NTN 6dpi isolation seems to have failed, ' \
      'please repeat nanodrop measurement.'
    )
    temp_result.table = Table.new(
      created_by: user,
      contents: tab_content["module3"]["nanodrop"]
    )
    temp_result.save

    # Create result activity
    Activity.create(
      type_of: :add_result,
      project: project,
      my_module: my_modules[2],
      user: user,
      created_at: temp_result.created_at,
      message: I18n.t(
        "activities.add_text_result",
        user: user.full_name,
        result: temp_result.name
      )
    )

    # Second result
    DelayedUploaderTutorial.delay(queue: :tutorial).generate_result_asset(
      my_module: my_modules[2],
      current_user: user,
      result_name: "Agarose gel electrophoresis of totRNA samples",
      created_at: generate_random_time(my_modules[2].created_at, 3.days),
      file_name: "totRNA_gel.jpg"
    )

    # ----------------- Module 4 ------------------
    module_step_names = [
      "Use Nano chip for testing RNA integrity"
    ]
    module_step_descriptions = [
      nil
    ]
    generate_module_steps(my_modules[3], module_step_names, module_step_descriptions)

    # Add file to existig step
    DelayedUploaderTutorial.delay(queue: :tutorial).add_step_asset(
      step: my_modules[3].protocol.steps.where("position = 0").take,
      current_user: user,
      file_name: "G2938-90034_KitRNA6000Nano_ebook.pdf"
    )

    # Results
    DelayedUploaderTutorial.delay(queue: :tutorial).generate_result_asset(
      my_module: my_modules[3],
      current_user: user,
      result_name: "Result of RNA integrity",
      created_at: generate_random_time(my_modules[3].created_at, 2.days),
      file_name: "Bioanalyser_result.JPG"
    )

    # ----------------- Module 5 ------------------
    module_step_names = [
      "RNA denaturation",
      "Prepare mastermix for RT",
      "RT reaction"
    ]
    module_step_descriptions = [
      "1 ug of RNA denature at 80°C for 5 min --> ice",
      "High Capacity cDNA Reverse Transcription Kit (Applied Biosystems)",
      "25°C for 10 min 37°C for 2 h"
    ]
    generate_module_steps(my_modules[4], module_step_names, module_step_descriptions)

    module_checklist_items = [
      "RT buffer",
      "dNTP mix",
      "Random Primers",
      "RNase inhibitor",
      "Reverse transcriptase",
      "Optional: Luciferase mRNA (denatured)",
      "H2O to 12.5 ul"
    ]

    # Add checklist to step
    step = my_modules[4].protocol.steps.where("position = 1").take
    checklist = Checklist.new(
      name: "Mastermix",
      step: step
    )

    module_checklist_items.each do |item|
      checklist.checklist_items << ChecklistItem.new(
        text: item
      )
    end
    checklist.save

    # ----------------- Module 6 ------------------
    module_step_names = [
      "Sample preparation",
      "Reaction setup",
      "Use Applied Biosystem 7300 instrument for qPCR",
      "Setup of the 96 plate"
    ]
    module_step_descriptions = [
      nil,
      nil,
      "Use following cycling condtions:",
      "Template of the 96-well plate"
    ]
    generate_module_steps(my_modules[5], module_step_names, module_step_descriptions)

    # Add file to existig steps
    DelayedUploaderTutorial.delay(queue: :tutorial).add_step_asset(
      step: my_modules[5].protocol.steps.where("position = 0").take,
      current_user: user,
      file_name: "sample_preparation.JPG"
    )

    DelayedUploaderTutorial.delay(queue: :tutorial).add_step_asset(
      step: my_modules[5].protocol.steps.where("position = 1").take,
      current_user: user,
      file_name: "reaction_setup.JPG"
    )

    DelayedUploaderTutorial.delay(queue: :tutorial).add_step_asset(
      step: my_modules[5].protocol.steps.where("position = 2").take,
      current_user: user,
      file_name: "cycling_conditions.JPG"
    )

    DelayedUploaderTutorial.delay(queue: :tutorial).add_step_asset(
      step: my_modules[5].protocol.steps.where("position = 3").take,
      current_user: user,
      file_name: "96plate.doc"
    )

    # Results
    # Add a hard-coded table result
    temp_result = Result.new(
      name: "Sample distribution on the plate",
      my_module: my_modules[5],
      user: user,
      created_at: generate_random_time(my_modules[5].created_at, 1.days)
    )
    temp_result.table = Table.new(
      created_by: user,
      contents: tab_content["module6"]["distribution"] % {sample0: samples_to_assign[0].name,
                                                          sample1: samples_to_assign[1].name,
                                                          sample2: samples_to_assign[2].name,
                                                          sample3: samples_to_assign[3].name}
    )
    temp_result.save

    # Create result activity
    Activity.create(
      type_of: :add_result,
      project: project,
      my_module: my_modules[5],
      user: user,
      created_at: temp_result.created_at,
      message: I18n.t(
        "activities.add_table_result",
        user: user.full_name,
        result: temp_result.name
      )
    )

    # Results
    DelayedUploaderTutorial.delay(queue: :tutorial).generate_result_asset(
      my_module: my_modules[5],
      current_user: user,
      result_name: "Mixtures and plate setup",
      created_at: generate_random_time(my_modules[5].created_at, 2.days),
      file_name: "Mixes_Templats.xls"
    )

    DelayedUploaderTutorial.delay(queue: :tutorial).generate_result_asset(
      my_module: my_modules[5],
      current_user: user,
      result_name: "Raw data from ABI 7300",
      created_at: generate_random_time(my_modules[5].created_at, 3.days),
      file_name: "BootCamp-Experiment-results-20122.sds"
    )

    DelayedUploaderTutorial.delay(queue: :tutorial).generate_result_asset(
      my_module: my_modules[5],
      current_user: user,
      result_name: "All results - curves",
      created_at: generate_random_time(my_modules[5].created_at, 4.days),
      file_name: "curves.JPG"
    )

    # ----------------- Module 7 ------------------
    module_step_names = [
      "Check negative controls NTC",
      "Eliminate results that have positive NTCs"
    ]
    module_step_descriptions = [
      "They have to be negative when using TaqMan assays. If they are positive when using SYBR assays check also melitng curve where signal comes from. - if it is primer dimer result is negative - If it is specific signal it is positive",
      "And repeat procedure"
    ]
    generate_module_steps(my_modules[6], module_step_names, module_step_descriptions)

    # Add comment to step
    step = my_modules[6].protocol.steps.where("position = 1").take
    step.save
    generate_step_comment(
      step,
      user,
      'What is the Cq that should be considered as positive result?'
    )

    # ----------------- Module 8 ------------------
    module_step_names = [
      "Template for ddCq analysis"
    ]
    module_step_descriptions = [
      nil
    ]
    generate_module_steps(my_modules[7], module_step_names, module_step_descriptions)

    # Add file to existig step
    DelayedUploaderTutorial.delay(queue: :tutorial).add_step_asset(
      step: my_modules[7].protocol.steps.where("position = 0").take,
      current_user: user,
      file_name: "ddCq-quantification_diagnostics-template.xls"
    )

    # Add result
    DelayedUploaderTutorial.delay(queue: :tutorial).generate_result_asset(
      my_module: my_modules[7],
      current_user: user,
      result_name: "Results of ddCq method",
      created_at: generate_random_time(my_modules[7].created_at, 1.days),
      file_name: "ddCq-quantification_diagnostics-results.xls"
    )

    DelayedUploaderTutorial.delay(queue: :tutorial).generate_result_asset(
      my_module: my_modules[7],
      current_user: user,
      result_name: "Dilution curve and efficiency",
      created_at: generate_random_time(my_modules[7].created_at, 2.days),
      file_name: "dilution_curve-efficiency.JPG"
    )

    DelayedUploaderTutorial.delay(queue: :tutorial).generate_result_asset(
      my_module: my_modules[7],
      current_user: user,
      result_name: "Relative quantification results",
      created_at: generate_random_time(my_modules[7].created_at, 3.days),
      file_name: "result-ddCq.JPG"
    )

    # Add a text result
    temp_result = Result.new(
      name: "Markdown remarks",
      my_module: my_modules[7],
      user: user,
      created_at: generate_random_time(my_modules[7].created_at, 4.days)
    )
    temp_text = "__Bolded text__\n\ndouble Enter to go to new line\n\n- bulletpoint"
    temp_result.result_text = ResultText.new(
      text: temp_text
    )
    temp_result.save

    # Create result activity
    Activity.create(
      type_of: :add_result,
      project: project,
      my_module: my_modules[7],
      user: user,
      created_at: temp_result.created_at,
      message: I18n.t(
        "activities.add_text_result",
        user: user.full_name,
        result: temp_result.name
      )
    )

    # create thumbnail
    experiment.generate_workflow_img

    # Lastly, create cookie with according ids
    # so tutorial steps can be properly positioned
    JSON.generate([
      organization: org.id,
      project: project.id,
      qpcr_module: my_modules[5].id
    ])
  end


  # WARNING: This only works on PostgreSQL
  def pluck_random(scope)
    scope.order("RANDOM()").first
  end

  def generate_random_time(*args)
    early = args[0]
    if args.size == 1
      rand(early..Time.now)
    else
      late = early + args[1]
      late = Time.now if late > Time.now
      rand(early..late)
    end
  end


  # Create steps for given module
  def generate_module_steps(my_module, step_names, step_descriptions)
    step_names.each_with_index do |name, i|
      created_at = generate_random_time(my_module.created_at, 5.hours)
      completed = rand <= 0.3
      completed_on = completed ?
        generate_random_time(created_at, 10.hours) : nil

      step = Step.create(
        created_at: created_at,
        name: name,
        description: step_descriptions[i],
        position: i,
        completed: completed,
        user: @user,
        protocol: my_module.protocol,
        completed_on: completed_on
      )

      # Create activity
      Activity.create(
        type_of: :create_step,
        project: my_module.experiment.project,
        my_module: my_module,
        user: step.user,
        created_at: created_at,
        message: I18n.t(
          "activities.create_step",
          user: step.user.full_name,
          step: i,
          step_name: step.name
        )
      )
      if completed then
        Activity.create(
          type_of: :complete_step,
          project: my_module.experiment.project,
          my_module: my_module,
          user: step.user,
          created_at: completed_on,
          message: I18n.t(
            "activities.complete_step",
            user: step.user.full_name,
            step: i+1,
            step_name: step.name,
            completed: my_module.protocol.completed_steps.count,
            all: i+1
          )
        )

        # Also add random comments to completed steps
        if rand < 0.3
          polite_comment = "This looks well."
        elsif rand < 0.4
          polite_comment = "Seems satisfactory."
        elsif rand < 0.4
          polite_comment = "Try a bit harder next time."
        end
        if polite_comment
          commented_on = generate_random_time(completed_on)
          generate_step_comment(
            step,
            @user,
            polite_comment,
            commented_on
          )
        end
      end
    end
  end

  def generate_project_comment(project, user, message, created_at = nil)
    created_at ||= generate_random_time(project.created_at, 1.week)
    project.comments << Comment.create(
      user: user,
      message: message,
      created_at: created_at
    )
    Activity.create(
      type_of: :add_comment_to_project,
      user: user,
      project: project,
      created_at: created_at,
      message: t('activities.add_comment_to_project',
                 user: user.full_name,
                 project: project.name)
    )
  end

  def generate_module_comment(my_module, user, message, created_at = nil)
    created_at ||= generate_random_time(my_module.created_at, 1.day)
    my_module.comments << Comment.create(
      user: user,
      message: message,
      created_at: created_at
    )
    Activity.create(
      type_of: :add_comment_to_module,
      user: user,
      project: my_module.experiment.project,
      my_module: my_module,
      created_at: created_at,
      message: t('activities.add_comment_to_module',
                 user: user.full_name,
                 module: my_module.name)
    )
  end

  def generate_result_comment(result, user, message, created_at = nil)
    created_at ||= generate_random_time(result.created_at, 1.days)
    result.comments << Comment.new(
      user: user,
      message: message,
      created_at: created_at
    )
    Activity.create(
      type_of: :add_comment_to_result,
      user: user,
      project: result.my_module.experiment.project,
      my_module: result.my_module,
      created_at: created_at,
      message: t('activities.add_comment_to_result',
                 user: user.full_name,
                 result: result.name)
    )
  end

  def generate_step_comment(step, user, message, created_at = nil)
    created_at ||= generate_random_time(step.created_at, 2.hours)
    step.comments << Comment.new(
      user: user,
      message: message,
      created_at: created_at
    )
    Activity.create(
      type_of: :add_comment_to_step,
      user: user,
      project: step.protocol.my_module.experiment.project,
      my_module: step.protocol.my_module,
      created_at: created_at,
      message: t('activities.add_comment_to_step',
                 user: user.full_name,
                 step: step.position + 1,
                 step_name: step.name)
    )
  end
end
