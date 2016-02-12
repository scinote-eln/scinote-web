module FirstTimeDataGenerator

  # Create data for tutorial for new users
  def seed_demo_data user
    @user = user

    # First organization that this user created
    # should contain the "intro" project
    org = user
      .organizations
      .where(created_by: user)
      .order(created_at: :asc)
      .first

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

    project = Project.create(
      visibility: 1,
      name: "Demo project - qPCR",
      due_date: nil,
      organization: org,
      created_by: user,
      created_at: Time.now - 1.week,
      last_modified_by: user,
      archived: false,
      archived_by: nil,
      archived_on: nil,
      restored_by: nil,
      restored_on: nil
    )

    # Automatically assign project author onto project
    UserProject.create(
      user: user,
      project: project,
      role: 0,
      created_at: Time.now - 1.week
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
    project.comments << Comment.create(
      user: user,
      message: "I've created a demo project",
      created_at: Time.now - 1.week
    )

    # Create a module group
    my_module_group = MyModuleGroup.create(
      name: "Potato qPCR workflow",
      project: project
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
        created_at: Time.now - rand(6).days,
        due_date: Time.now + (2 * i + 1).weeks,
        description: i == 5 ? qpcr_module_description : nil,
        x: i < 4 ? i % 4 : 7 - i,
        y: i/4,
        project: project,
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
        created_at: my_module.created_at + 2.minutes
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
        created_at: my_module.created_at + 2.minutes
      )
    end

    # Create an archived module
    archived_module = MyModule.create(
      name: "Data analysis - Pfaffl method",
      created_by: user,
      created_at: Time.now - rand(4..6).days,
      due_date: Time.now + 1.week,
      description: nil,
      x: -1,
      y: -1,
      project: project,
      workflow_order: -1,
      my_module_group: nil,
      archived: true,
      archived_on: Time.now - rand(3).days,
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
      created_at: archived_module.created_at + 2.minutes
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
      created_at: archived_module.created_at + 2.minutes
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
    my_modules[0].comments << Comment.create(
      user: user,
      message: "We should have a meeting to discuss sampling parametrs soon.",
      created_at: my_modules[0].created_at + 1.day
    )
    my_modules[0].comments << Comment.create(
      user: user,
      message: "I agree."
    )

    my_modules[1].comments << Comment.create(
      user: user,
      message: "The samples have arrived.",
      created_at: my_modules[0].created_at + 2.days
    )

    my_modules[2].comments << Comment.create(
      user: user,
      message: "Due date has been postponed for a day.",
      created_at: my_modules[0].created_at + 1.days
    )

    my_modules[4].comments << Comment.create(
      user: user,
      message: "Please show Steve the RT procedure.",
      created_at: my_modules[0].created_at + 2.days
    )

    my_modules[5].comments << Comment.create(
      user: user,
      message: "The results must be very definitive.",
      created_at: my_modules[0].created_at + 3.days
    )

    my_modules[7].comments << Comment.create(
      user: user,
      message: "The due date here is flexible.",
      created_at: my_modules[0].created_at + 3.days
    )


    # Create module steps
    # Module 1
    module_step_names = [
      "Gene expression"
    ]
    module_step_descriptions = [
      "Compare response of PVYNTN, cab4 and PR1 genes in mock/virus inoculated potatoes & in time"
    ]
    generate_module_steps(my_modules[0], module_step_names, module_step_descriptions)

    # Module 2
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

    # Module 3
    module_step_names = [
      "Homogenization of the material",
      "Isolation of RNA with RNeasy plant mini kit"
    ]
    module_step_descriptions = [
      " Use tissue lyser: 1 min on step 3.",
      nil
    ]
    generate_module_steps(my_modules[2], module_step_names, module_step_descriptions)

    # Module 4
    module_step_names = [
      "Use Nano chip for testing RNA integrity"
    ]
    module_step_descriptions = [
      nil
    ]
    generate_module_steps(my_modules[3], module_step_names, module_step_descriptions)

    # Module 5
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

    # Module 6
    module_step_names = [
      "Sample preparation",
      "Reaction setup",
      "Setup of the 96 plate"
    ]
    module_step_descriptions = [
      nil,
      nil,
      "Template of the 96-well plate"
    ]
    generate_module_steps(my_modules[5], module_step_names, module_step_descriptions)

    # Module 7
    module_step_names = [
      "Check negative controls NTC",
      "Eliminate results that have positive NTCs"
    ]
    module_step_descriptions = [
      "They have to be negative when using TaqMan assays. If they are positive when using SYBR assays check also melitng curve where signal comes from. - if it is primer dimer result is negative - If it is specific signal it is positive",
      "And repeat procedure"
    ]
    generate_module_steps(my_modules[6], module_step_names, module_step_descriptions)

    # Module 8
    module_step_names = [
      "Template for ddCq analysis"
    ]
    module_step_descriptions = [
      nil
    ]
    generate_module_steps(my_modules[7], module_step_names, module_step_descriptions)


    # Add a text result
    temp_result = Result.new(
      name: "Number of samples",
      my_module: my_modules[1],
      user: user,
      created_at: my_modules[1].created_at + rand(20).hours,
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

    # Add a hard-coded table result
    temp_result = Result.new(
      name: "Sample distribution on the plate",
      my_module: my_modules[5],
      user: user,
      created_at: my_modules[5].created_at + rand(20).hours,
    )
    temp_result.table = Table.new(
      created_by: user,
      contents: { data: [
        ["#{samples_to_assign[0].name} (100x)","","#{samples_to_assign[0].name} (100x)","","#{samples_to_assign[0].name} (100x)","","#{samples_to_assign[0].name} (100x)","","#{samples_to_assign[0].name} (100x)","","#{samples_to_assign[0].name} (100x)","","#{samples_to_assign[0].name} (100x)","","#{samples_to_assign[0].name} (100x)","","","","Mix smpl (10x)","","Mix smpl (10x)",""],
        ["#{samples_to_assign[0].name} (1000x)","","#{samples_to_assign[0].name} (1000x)","","#{samples_to_assign[0].name} (1000x)","","#{samples_to_assign[0].name} (1000x)","","#{samples_to_assign[0].name} (1000x)","","#{samples_to_assign[0].name} (1000x)","","#{samples_to_assign[0].name} (1000x)","","#{samples_to_assign[0].name} (1000x)","","","","Mix smpl (100x)","","Mix smpl (100x)",""],
        ["#{samples_to_assign[1].name} (100x)","","#{samples_to_assign[1].name} (100x)","","#{samples_to_assign[1].name} (100x)","","#{samples_to_assign[1].name} (100x)","","#{samples_to_assign[1].name} (100x)","","#{samples_to_assign[1].name} (100x)","","#{samples_to_assign[1].name} (100x)","","#{samples_to_assign[1].name} (100x)","","","","Mix smpl (1000x)","","Mix smpl (1000x)",""],
        ["#{samples_to_assign[1].name} (1000x)","","#{samples_to_assign[1].name} (1000x)","","#{samples_to_assign[1].name} (1000x)","","#{samples_to_assign[1].name} (1000x)","","#{samples_to_assign[1].name} (1000x)","","#{samples_to_assign[1].name} (1000x)","","#{samples_to_assign[1].name} (1000x)","","#{samples_to_assign[1].name} (1000x)","","","","Mix smpl (10000x)","","Mix smpl (10000x)",""],
        ["#{samples_to_assign[2].name} (100x)","","#{samples_to_assign[2].name} (100x)","","#{samples_to_assign[2].name} (100x)","","#{samples_to_assign[2].name} (100x)","","#{samples_to_assign[2].name} (100x)","","#{samples_to_assign[2].name} (100x)","","#{samples_to_assign[2].name} (100x)","","#{samples_to_assign[2].name} (100x)","","","","NTC1","NTC2","#{samples_to_assign[2].name} (100x)",""],
        ["#{samples_to_assign[2].name} (1000x)","","#{samples_to_assign[2].name} (1000x)","","#{samples_to_assign[2].name} (1000x)","","#{samples_to_assign[2].name} (1000x)","","#{samples_to_assign[2].name} (1000x)","","#{samples_to_assign[2].name} (1000x)","","#{samples_to_assign[2].name} (1000x)","","#{samples_to_assign[2].name} (1000x)","","","","NTC1","NTC2","#{samples_to_assign[2].name} (1000x)",""],
        ["#{samples_to_assign[3].name} (100x)","","#{samples_to_assign[3].name} (100x)","","#{samples_to_assign[3].name} (100x)","","#{samples_to_assign[3].name} (100x)","","#{samples_to_assign[3].name} (100x)","","#{samples_to_assign[3].name} (100x)","","#{samples_to_assign[3].name} (100x)","","#{samples_to_assign[3].name} (100x)","","","","NTC1","NTC2","#{samples_to_assign[3].name} (100x)",""],
        ["#{samples_to_assign[3].name} (1000x)","","#{samples_to_assign[3].name} (1000x)","","#{samples_to_assign[3].name} (1000x)","","#{samples_to_assign[3].name} (1000x)","","#{samples_to_assign[3].name} (1000x)","","#{samples_to_assign[3].name} (1000x)","","#{samples_to_assign[3].name} (1000x)","","#{samples_to_assign[3].name} (1000x)","","","","NTC1","NTC2","#{samples_to_assign[3].name} (1000x)",""]
      ]}.to_json
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

    # Lastly, create cookie with according ids
    # so tutorial steps can be properly positioned
    return JSON.generate([
      organization: org.id,
      project: project.id,
      qpcr_module: my_modules[5].id
    ])
  end

  # WARNING: This only works on PostgreSQL
  def pluck_random(scope)
    scope.order("RANDOM()").first
  end

  # Create steps for given module
  def generate_module_steps(my_module, step_names, step_descriptions)
    step_names.each_with_index do |name, i|
      created_at = my_module.created_at + rand(1..5).days
      completed = rand <= 0.3
      completed_on = completed ?
        created_at + rand(10).hours : nil

      step = Step.create(
        created_at: created_at,
        name: name,
        description: step_descriptions[i],
        position: i,
        completed: completed,
        user: @user,
        my_module: my_module,
        completed_on: completed_on
      )

      # Create activity
      Activity.create(
        type_of: :create_step,
        project: my_module.project,
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
          project: my_module.project,
          my_module: my_module,
          user: step.user,
          created_at: completed_on,
          message: I18n.t(
            "activities.complete_step",
            user: step.user.full_name,
            step: i+1,
            step_name: step.name,
            completed: my_module.completed_steps.count,
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
          commented_on = completed_on + rand(500).minutes
          step.comments << Comment.create(
            user: @user,
            message: polite_comment,
            created_at: commented_on
          )
          Activity.create(
            type_of: :add_comment_to_step,
            project: my_module.project,
            my_module: my_module,
            user: @user,
            created_at: commented_on,
            message: I18n.t(
              "activities.add_comment_to_step",
              user: @user.full_name,
              step: i,
              step_name: step.name
            )
          )
        end
      end
    end
  end

end