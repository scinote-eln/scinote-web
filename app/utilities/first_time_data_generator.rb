module FirstTimeDataGenerator
  # Default inventory repository
  REPO_SAMPLES_NAME = 'Samples'.freeze

  # Create data for demo for new users
  def seed_demo_data(user, team, asset_queue = :demo)
    @user = user

    # If private private team does not exist,
    # there was something wrong with user creation.
    # Do nothing
    return unless team

    # Skip this team if user already has a demo project
    return if team.projects.where(demo: true).any?

    name = '[NEW] Demo project by SciNote'
    exp_name = 'Polymerase chain reaction'
    # If there is an existing demo project, archive and rename it
    if team.projects.where(name: name).present?
      # TODO: check if we still need this code
      # old = team.projects.where(name: 'Demo project - qPCR')[0]
      # old.archive! user
      i = 1
      while team.projects.where(
        name: name = "#{name} (#{i})"
      ).present?
        i += 1
      end
    end

    project = Project.create(
      visibility: 0,
      name: name,
      due_date: nil,
      team: team,
      created_by: user,
      created_at: generate_random_time(1.week.ago),
      last_modified_by: user,
      archived: false,
      template: false,
      demo: true
    )

    # check if samples repo already exist, then create custom repository samples
    repository = Repository.where(team: team).where(name: REPO_SAMPLES_NAME)
    repository =
      if repository.blank?
        if team.repositories.count < Rails.configuration.x.repositories_limit
          Repository.create(
            name: REPO_SAMPLES_NAME,
            team: team,
            created_by: user
          )
        else
          # User first repo just as a placeholder, this call will fail anyhow
          Repository.create(
            name: team.repositories.first.name,
            team: team,
            created_by: user
          )
        end
      else
        repository.first
      end

    # create list value column for sample types
    repo_columns = []
    ['Sample Types', 'Sample Groups'].each do |repo_name|
      repo_column = repository.repository_columns.where(name: repo_name)

      repo_columns <<
        if repo_column.blank?
          RepositoryColumn.create(
            repository: repository,
            created_by: user,
            data_type: :RepositoryListValue,
            name: repo_name
          )
        else
          repo_column.first
        end
    end

    # Maintain old names
    repository_column_sample_types, repository_column_sample_groups =
      repo_columns

    # create few list items for sample types
    repository_items_sample_types = []
    ['Potato leaves', 'Tea leaves', 'Potato bug'].each do |name|
      item = RepositoryListItem.create(
        data: name,
        created_by: user,
        last_modified_by: user,
        repository_column: repository_column_sample_types,
        repository: repository
      )

      # Check if it already exists
      if item.persisted?
        repository_items_sample_types << item
      else
        repository_items_sample_types << repository_column_sample_types
                                         .repository_list_items
                                         .where(data: name).first
      end
    end

    # create few list items for sample groups
    repository_items_sample_groups = []
    %i(Fodder Nutrient Seed).each do |name|
      item = RepositoryListItem.create(
        data: name,
        created_by: user,
        last_modified_by: user,
        repository_column: repository_column_sample_groups,
        repository: repository
      )

      # Check if it already exists
      if item.persisted?
        repository_items_sample_groups << item
      else
        repository_items_sample_groups << repository_column_sample_groups
                                          .repository_list_items
                                          .where(data: name).first
      end
    end

    repository_rows_to_assign = []
    # Generate random custom respository sample names and assign sample types
    # and groups

    repository_sample_name = (0...3).map { 65.+(rand(26)).chr }.join << '/'
    (1..5).each do |index|
      repository_row = RepositoryRow.create(
        repository: repository,
        created_by: user,
        last_modified_by: user,
        name: repository_sample_name + index.to_s
      )
      RepositoryListValue.create(
        created_by: user,
        last_modified_by: user,
        repository_list_item: repository_items_sample_types[
          rand(0..(repository_items_sample_types.length - 1))
        ],
        repository_cell_attributes: {
          repository_row: repository_row,
          repository_column: repository_column_sample_types
        }
      )
      RepositoryListValue.create(
        created_by: user,
        last_modified_by: user,
        repository_list_item: repository_items_sample_groups[
          rand(0..(repository_items_sample_groups.length - 1))
        ],
        repository_cell_attributes: {
          repository_row: repository_row,
          repository_column: repository_column_sample_groups
        }
      )
      repository_rows_to_assign << repository_row
    end
    # Create sample types
    SampleType.create(
      name: 'Potato leaves',
      team: team
    )

    SampleType.create(
      name: 'Tea leaves',
      team: team
    )

    SampleType.create(
      name: 'Potato bug',
      team: team
    )

    SampleGroup.create(
      name: 'Fodder',
      team: team,
      color: Constants::TAG_COLORS[1]
    )

    SampleGroup.create(
      name: 'Nutrient',
      team: team,
      color: Constants::TAG_COLORS[0]
    )

    SampleGroup.create(
      name: 'Seed',
      team: team,
      color: Constants::TAG_COLORS[2]
    )

    samples = []
    # Generate random sample names start
    # and put it on the beginning of 5 samples
    sample_name = (0...3).map{65.+(rand(26)).chr}.join << '/'
    for i in 1..5
      samples << Sample.create(
        name: sample_name + i.to_s,
        team: team,
        user: user,
        sample_type: rand < 0.8 ? pluck_random(team.sample_types) : nil,
        sample_group: rand < 0.8 ? pluck_random(team.sample_groups) : nil
      )
    end

    sample_name = (0...3).map{65.+(rand(26)).chr}.join << '/'
    for i in 1..5
      samples << Sample.create(
        name: sample_name + i.to_s,
        team: team,
        user: user,
        sample_type: rand < 0.8 ? pluck_random(team.sample_types) : nil,
        sample_group: rand < 0.8 ? pluck_random(team.sample_groups) : nil
      )
    end

    experiment_description =
      'Polymerase chain reaction (PCR) monitors the amplification of DNA ' \
      'in real time (qPCR cyclers constantly scan qPCR plates). It is, in ' \
      'contrast to the conventional PCR, quantitative, meaning that it ' \
      'enables us to determine the exact concentration (relative or ' \
      'absolute) of the amplified DNA in the sample. Conversely, in ' \
      'conventional PCR we can see the result of amplification only after ' \
      'the PCR is completed (end-point detection).

       Apart from DNA, RNA can also be used as a template (e.g. in case of ' \
      'gene expression studies or detection of RNA viruses). In this case, ' \
      'the RNA needs to be reverse transcribed into DNA (also termed ' \
      'complementary DNA or cDNA) before it is amplified with real-time PCR. ' \
      'There is a term for this combined method: real-time reverse ' \
      'transcription PCR or qRT-PCR (sometimes RT-qPCR) for short.'

    experiment = Experiment.create(
      name: exp_name,
      description: experiment_description,
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

    # Add a comment
    generate_project_comment(
      project,
      user,
      'I\'ve created a demo project'
    )

    # Create a module group
    my_module_group = MyModuleGroup.create(
      experiment: experiment
    )

    # Create project modules
    my_modules = []
    my_module_names = [
      'Experiment design',
      'Sampling biological material',
      'RNA isolation',
      'RNA quality & quantity - BIOANALYSER',
      'Reverse transcription',
      'qPCR',
      'Data quality control',
      'Data analysis - ddCq'
    ]

    qpcr_module_description = 'PCR is a method where an enzyme
      (thermostable DNA polymerase, originally isolated in 1960s
      from bacterium Thermus aquaticus, growing in hot lakes of
      Yellowstone park, USA) amplifies a short specific part of
      the template DNA (amplicon) in cycles. In every cycle the
      number of short specific sections of DNA is doubled, leading
      to an exponential amplification of targets. More on how
      conventional PCR works can be found here.'

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
          output_id: my_modules[i - 1].id
        )
      end

      UserMyModule.create(
        user: user,
        my_module: my_module,
        assigned_by: user,
        created_at: generate_random_time(my_module.created_at, 2.minutes)
      )
    end

    # Create an archived module
    archived_module = MyModule.create(
      name: 'Data analysis - Pfaffl method',
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

    # Assign new user to archived module
    UserMyModule.create(
      user: user,
      my_module: archived_module,
      assigned_by: user,
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

    my_modules[1].downstream_modules.each do |mm|
      samples_to_assign.each do |s|
        SampleMyModule.create(
          sample: s,
          my_module: mm
        )
      end
      repository_rows_to_assign.each do |repository_row|
        MyModuleRepositoryRow.create!(
          repository_row: repository_row,
          my_module: mm,
          assigned_by: user
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
      name: 'Dry lab',
      color: Constants::TAG_COLORS[0],
      project: project,
      created_by: user,
      last_modified_by: user
    )
    wetlab_tag = Tag.create(
      name: 'Wet lab',
      color: Constants::TAG_COLORS[12],
      project: project,
      created_by: user,
      last_modified_by: user
    )
    plant_tag = Tag.create(
      name: 'Plant',
      color: Constants::TAG_COLORS[5],
      project: project,
      created_by: user,
      last_modified_by: user
    )
    virus_tag = Tag.create(
      name: 'Pathogenic virus',
      color: Constants::TAG_COLORS[13],
      project: project,
      created_by: user,
      last_modified_by: user
    )
    infectious_tag = Tag.create(
      name: 'Infectious sample',
      color: Constants::TAG_COLORS[2],
      project: project,
      created_by: user,
      last_modified_by: user
    )
    bacteria_tag = Tag.create(
      name: 'Bacteria',
      color: Constants::TAG_COLORS[14],
      project: project,
      created_by: user,
      last_modified_by: user
    )
    patent_tag = Tag.create(
      name: 'Results for patent',
      color: Constants::TAG_COLORS[3],
      project: project,
      created_by: user,
      last_modified_by: user
    )
    identifires_tag = Tag.create(
      name: 'Assign unique identifires',
      color: Constants::TAG_COLORS[15],
      project: project,
      created_by: user,
      last_modified_by: user
    )
    plasmid_tag = Tag.create(
      name: 'Plasmid A',
      color: Constants::TAG_COLORS[1],
      project: project,
      created_by: user,
      last_modified_by: user
    )

    # Add tags to module
    my_modules[0].tags << drylab_tag

    my_modules[1].tags << wetlab_tag
    my_modules[1].tags << plant_tag
    my_modules[1].tags << virus_tag

    my_modules[2].tags << plant_tag
    my_modules[2].tags << infectious_tag

    my_modules[3].tags << wetlab_tag

    my_modules[4].tags << wetlab_tag
    my_modules[4].tags << bacteria_tag

    my_modules[5].tags << wetlab_tag
    my_modules[5].tags << bacteria_tag
    my_modules[5].tags << virus_tag
    my_modules[5].tags << patent_tag
    my_modules[5].tags << identifires_tag

    my_modules[6].tags << drylab_tag
    my_modules[6].tags << plasmid_tag

    my_modules[7].tags << drylab_tag
    my_modules[7].tags << plasmid_tag
    my_modules[7].save

    # Load table contents yaml file
    tab_content = YAML.load_file(
      "#{Rails.root}/app/assets/demo_files/tables_content.yaml"
    )

    # Create module content
    # ----------------- Module 1 ------------------
    module_step_names = [
      'Gene expression'
    ]
    module_step_descriptions = [
      'Compare response of PVYNTN, cab4 and PR1 genes in mock/virus ' \
      'inoculated potatoes & in time'
    ]
    generate_module_steps(my_modules[0],
                          module_step_names,
                          module_step_descriptions)

    step = my_modules[0].protocol.steps.where('position = 0').take
    Table.create(
      name: 'Experiment design table',
      created_by: user,
      step: step,
      team: team,
      contents: tab_content['module1']['experimental_design_table']
    )

    # ----------------- Module 2 ------------------
    module_step_names = [
      'Inoculation of potatoes',
      'Store samples',
      'Collection of potatoes'
    ]

    second_rep_item = smart_annotate_rep_item(repository_rows_to_assign.second)
    third_rep_item = smart_annotate_rep_item(repository_rows_to_assign.third)
    fifth_rep_item = smart_annotate_rep_item(repository_rows_to_assign.fifth)
    module_step_descriptions = [
      '<html>
        <body>
          <p>50% of samples should be mock inoculated
          <span class=\"atwho-inserted\"contenteditable=\"false\"
            data-atwho-at-query=\"#\">[#' + third_rep_item + ']</span>
          <span class=\"atwho-inserted\" contenteditable=\"false\"
            data-atwho-at-query=\"#\">[#' + fifth_rep_item + ']</span>
          while other 50% with PVY NTN virus
          <span class=\"atwho-inserted\" contenteditable=\"false\"
            data-atwho-at-query=\"#\">[#' + third_rep_item + ']</span>
          <span class=\"atwho-inserted\" contenteditable=\"false\"
            data-atwho-at-query=\"#\">[#' + fifth_rep_item + ']</span>.
          </p>
        </body>
      </html>',
      'Collect samples in <strong>2ml tubes</strong> and put them in '\
      '<strong>liquid nitrogen</strong> and store at <strong>80°C</strong>.',
      '50% of PVYNTN inoculated potatos and 50% of Mock inoculated potatos ' \
      'collect 1 day post inocullation while other halph of samples collect ' \
      '6 days post inoculation.'
    ]
    generate_module_steps(my_modules[1],
                          module_step_names,
                          module_step_descriptions)

    # Delete repository items, if we went over the limit
    repository_rows_to_assign.map(&:destroy) unless repository.id

    # Add table to existig step
    step = my_modules[1].protocol.steps.where('position = 0').take
    Table.create(
      created_by: user,
      step: step,
      team: team,
      contents: tab_content['module2']['samples_table']
    )
    # Add file to existig step
    DelayedUploaderDemo.delay(queue: asset_queue).add_step_asset(
      step: my_modules[1].protocol.steps.where('position = 0').take,
      current_user: user,
      current_team: team,
      file_name: 'PVY-inoculated_plant_symptoms.JPG'
    )
    # Add comment to step 1
    user_annotation = user.name
    generate_step_comment(
      step,
      user,
      "#{user_annotation} I have used different sample [##{second_rep_item}]"
    )
    # Add comment to step 3
    step = my_modules[1].protocol.steps.where('position = 2').take
    generate_step_comment(
      step,
      user,
      user_annotation + ' Please complete this by Monday.'
    )
    # Results
    DelayedUploaderDemo.delay(queue: asset_queue).generate_result_asset(
      my_module: my_modules[1],
      current_user: user,
      current_team: team,
      result_name: 'Mock inoculated plant',
      created_at: generate_random_time(my_modules[1].created_at, 2.days),
      file_name: 'mock-inoculated-plant.JPG'
    )

    DelayedUploaderDemo.delay(queue: asset_queue).generate_result_asset(
      my_module: my_modules[1],
      current_user: user,
      current_team: team,
      result_name: 'Plant',
      created_at: generate_random_time(my_modules[1].created_at, 3.days),
      file_name: '6dpi_height.JPG'
    )

    # Add a text result
    temp_result = Result.new(
      name: 'Number of samples',
      my_module: my_modules[1],
      user: user,
      created_at: generate_random_time(my_modules[1].created_at, 4.days)
    )
    temp_text = "There are many biological replicates we harvested " \
                "for each type of sample (code-names):\n\n"
    samples_to_assign.each do |s|
      temp_text << "* #{s.name}\n\n"
    end
    temp_result.result_text = ResultText.new(
      text: temp_text
    )
    temp_result.save

    # ----------------- Module 3 ------------------
    module_step_names = [
      'Homogenization of the material',
      'Isolation of RNA with RNeasy plant mini kit',
      'Disruption with mortar and pestle',
      'Disruption',
      'Buffer addition',
      'Transfer the lysate to a QIAshredder spin column',
      'Addition of ethanol',
      'Transfer the sample',
      'Add 700 μL Buffer RW1 to the RNeasy spin column.',
      'Addition of buffer',
      'Place the RNeasy spin column in a new 1.5 ml collection tube',
      'If the expected RNA yield is >30 μg'
    ]
    module_step_descriptions = [
      'Use tissue lyser: 1 min on step 3.',
      'Disrupt a maximum of 100 mg plant material according to step 3 or 4.',
      'Immediately place tissue in liquid nitrogen. Grind thoroughly. ' \
      'Decant tissue powder and liquid nitrogen into RNase-free, ' \
      'liquid-nitrogen–cooled, 2 mL microcentrifuge tube (not supplied). ' \
      'Allow the liquid nitrogen to evaporate, but do not allow the tissue ' \
      'to thaw. Proceed immediately to step 5.',
      '<html><body><p>Disruption using the TissueLyser II, TissueLyser LT, '  \
      'or TissueRuptor.<br><br>For detailed information on disruption of ' \
      'plant tissues for purification of RNA, see TissueLyser Handbook, ' \
      'TissueLyser LT Handbook, or TissueRuptor Handbook. (The RNeasy Mini ' \
      'Handbook will be updated with this option.)</p></body></html>',
      'Add 450 μL Buffer RLT or Buffer RLC to a maximum of 100 mg tissue ' \
      'powder. Vortex vigorously.',
      'Transfer the lysate to a QIAshredder spin column placed in a 2 mL ' \
      'collection tube. Centrifuge for 2 min at full speed. Transfer the ' \
      'supernatant of the flow-through to a new microcentrifuge tube (not ' \
      'supplied) without disturbing the cell-debris pellet.',
      'Add 0.5 volume of ethanol (96–100%) to the cleared lysate, and mix ' \
      'immediately by pipetting. Do not centrifuge.',
      'Transfer the sample (usually 650 μl), with any precipitate, to an ' \
      'RNeasy Mini spin column (pink) in a 2 mL collection tube (supplied). ' \
      'Close the lid, and centrifuge for 15 s at ≥8000 x g (≥10,000 rpm). ' \
      'Discard the flowthrough.',
      'Close the lid, andcentrifuge for 15 s at ≥8000 x g. Discard the ' \
      'flow-through.',
      'Add 500 μL Buffer RPE to the RNeasy spin column. Close the lid, and ' \
      'centrifuge for 2 min at ≥8000 x g.',
      'Add 30–50 μL RNase-free water directly to the spin column membrane. ' \
      'Close the lid, and centrifuge for 1 min at ≥8000 x g to elute the RNA.',
      '<html><body><p>If the expected RNA yield is &gt;30 μg, repeat step 9 ' \
      'using another 30–50 μL of RNase-free water.<br>Alternatively, use the ' \
      'eluate from step 9 (if high RNA concentration is required). Reuse the ' \
      'collection tube from step 12.</p></body></html>'
    ]
    generate_module_steps(my_modules[2], module_step_names, module_step_descriptions)

    # Results
    temp_result = Result.new(
      name: 'Nanodrop results',
      my_module: my_modules[2],
      created_at: generate_random_time(my_modules[2].created_at, 1.days),
      user: user
    )
    qpcr_id = MyModule.where(name: 'qPCR').last.id.base62_encode
    DelayedUploaderDemo.generate_result_comment(
      temp_result,
      user,
      user_annotation + ' Please check if results match results in ' \
      '[#qPCR~tsk~' + qpcr_id + ']',
      generate_random_time(temp_result.created_at, 1.days)
    )
    temp_result.table = Table.new(
      created_by: user,
      team: team,
      contents: tab_content['module3']['nanodrop']
    )
    temp_result.save

    # Second result
    DelayedUploaderDemo.delay(queue: asset_queue).generate_result_asset(
      my_module: my_modules[2],
      current_user: user,
      current_team: team,
      result_name: 'Agarose gel electrophoresis of totRNA samples',
      created_at: generate_random_time(my_modules[2].created_at, 3.days),
      file_name: 'totRNA_gel.jpg',
      comment: user_annotation + ' Could you check if this is okay?'
    )

    # ----------------- Module 4 ------------------
    module_step_names = [
      'Before you start',
      'Excise the tissue sample from the animal or remove it from storage.',
      'Weigh the piece to be used, and place it into a suitably sized vessel ' \
      'for disruption and homogenization.',
      'Disrupt the tissue and homogenize the lysate in Buffer RLT',
      'Disruption and homogenization using a rotor–stator homogenizer',
      'Centrifuge the lysate for 3 min at full speed',
      'Add 1 volume of 70% ethanol* to the cleared lysate, and mix ' \
      'immediately by pipetting',
      'Transfer up to 700 µL of the sample',
      'Add 700 µL Buffer RW1 to the RNeasy spin column',
      'Add 500 µL Buffer RPE to the RNeasy spin column',
      'Place the RNeasy spin column in a new 1.5 mL collection tube (supplied)'
    ]
    module_step_descriptions = [
      'Follow the guidelines bellow.',
      '<html><body><p>Remove RNAlater stabilized tissues from the reagent ' \
      'using forceps. Determine the amount of tissue. Do not use more than ' \
      '30 mg.<br>Weighing tissue is the most accurate way to determine the ' \
      'amount.<br>Note: If the tissues were stored in RNAlater Reagent at ' \
      '–20°C, be sure to remove any crystals that may have formed.' \
      '</p></body></html>',
      '<html><body><p>RNA in harvested tissues is not protected until the '\
      'tissues are treated with RNAlater RNA Stabilization Reagent, '\
      'flash-frozen, or disrupted and homogenized in step 3. Frozen tissues ' \
      'should not be allowed to thaw during handling. The relevant ' \
      'procedures should be carried out as quickly as possible.<br><br>Note: ' \
      'Remaining fresh tissues can be placed into RNAlater RNA Stabilization ' \
      'Reagent to stabilize RNA (see protocol on page 34). However, ' \
      'previously frozen tissues thaw too slowly in the reagent, preventing ' \
      'the reagent from diffusing into the tissues quickly enough to prevent ' \
      'RNA degradation.</p></body></html>',
      '<html><body><p>See “Disrupting and homogenizing starting material”, ' \
      'pages 18–21, for more details on disruption and homogenization.' \
      '<br><br><strong>Note</strong>: Ensure that β-ME is added to Buffer ' \
      'RLT before use (see “Things to do before starting”).<br><br>After ' \
      'storage in RNAlater RNA Stabilization Reagent, tissues may become ' \
      'slightly harder than fresh or thawed tissues. Disruption and ' \
      'homogenization using standard methods is usually not a problem. For ' \
      'easier disruption and homogenization, we recommend using 600 µl ' \
      'Buffer RLT.<br><br><strong>Note</strong>: Incomplete homogenization ' \
      'leads to significantly reduced RNA yields and can cause clogging of ' \
      'the RNeasy spin column. Homogenization with the TissueLyser LT, ' \
      'TissueLyser II, and rotor–stator homogenizers generally results in ' \
      'higher RNA yields than with other methods.</p></body></html>',
      'Place the weighed (fresh, frozen, or RNAlater stabilized) tissue in a ' \
      'suitably sized vessel. Add the appropriate volume of Buffer RLT (see ' \
      'Table 8). Immediately disrupt and homogenize the tissue using a ' \
      'conventional rotor–stator homogenizer until it is uniformly ' \
      'homogeneous (usually 20–40 s).',
      '<html><body><p>Carefully remove the supernatant by pipetting, and ' \
      'transfer it to a new microcentrifuge tube (not supplied).<br><br>' \
      'Use only this supernatant (lysate) in subsequent steps. In some ' \
      'preparations, very small amounts of insoluble material will be ' \
      'present after the 3 min centrifugation, making the pellet ' \
      'invisible.</p></body></html>',
      '<html><body><span style="text-decoration: underline;">Do not ' \
      'centrifuge.</span><br><br><strong>Note</strong>: The volume of lysate ' \
      'may be less than 350 µL or 600 µL due to loss during homogenization ' \
      'and centrifugation in steps 3 and 4.<br><br><strong>Note</strong>: ' \
      'Precipitates may be visible after addition of ethanol. This does not ' \
      'affect the procedure.</body></html>',
      '<html><body><p>Transfer up to 700 µL of the sample, including any ' \
      'precipitate that may have formed, to an RNeasy spin column placed in ' \
      'a 2 mL collection tube (supplied).<br>Close the lid gently, and ' \
      'centrifuge for 15 s at ≥8000 x g (≥10,000 rpm). Discard the ' \
      'flow-through. If the sample volume exceeds 700 µL, centrifuge ' \
      'successive aliquots in the same RNeasy spin column. Discard the ' \
      'flow-through after each centrifugation.</p></body></html>',
      'Close the lid gently, and centrifuge for 15 s at ≥8000 x g (≥10,000 ' \
      'rpm) to wash the spin column membrane. Discard the flow-through.',
      '<html><body><p>Close the lid gently, and centrifuge for 2 min at ' \
      '≥8000 x g (≥10,000 rpm) to wash the spin column membrane.<br><br>The ' \
      'long centrifugation dries the spin column membrane, ensuring that no ' \
      'ethanol is carried over during RNA elution. Residual ethanol may ' \
      'interfere with downstream reactions.<br><br><strong>Note</strong>: ' \
      'After centrifugation, carefully remove the RNeasy spin column from ' \
      'the collection tube so that the column does not contact the flow-' \
      'through. Otherwise, carryover of ethanol will occur.</p></body></html>',
      'Add 30–50 µL RNase-free water directly to the spin column membrane. ' \
      'Close the lid gently, and centrifuge for 1 min at ≥8000 x g ' \
      '(≥10,000 rpm) to elute the RNA.'
    ]
    generate_module_steps(my_modules[3], module_step_names, module_step_descriptions)

    # Add file to existig step 1
    DelayedUploaderDemo.delay(queue: asset_queue).add_step_asset(
      step: my_modules[3].protocol.steps.where('position = 0').take,
      current_user: user,
      current_team: team,
      file_name: 'important_notes.pdf'
    )

    # Add checklist 1 to step 1
    step = my_modules[3].protocol.steps.where('position = 0').take
    checklist = Checklist.new(
      name: 'If using the RNeasy Kit for the first time, read ' \
            '"Important Notes" in the attached file',
      step: step
    )
    module_checklist_items = [
      'For optimal results, stabilize harvested tissues immediately in ' \
      'RNAlater RNA Stabilization Reagent (see protocol on page 34). Tissues ' \
      'can be stored in the reagent for up to 1 day at 37°C, 7 days at ' \
      '15–25°C, or 4 weeks at 2–8°C, or archived at –20°C or –80°C.',
      'Fresh, frozen, or RNAlater stabilized tissues can be used. Tissues ' \
      'can be stored at –70°C for several months. Flash-freeze tissues in ' \
      'liquid nitrogen, and immediately transfer to –70°C. Do not allow ' \
      'tissues to thaw during weighing or handling prior to disruption in ' \
      'Buffer RLT. Homogenized tissue lysates from step 4 can also be stored ' \
      'at –70°C for several months. Incubate frozen lysates at 37°C in a ' \
      'water bath until completely thawed and salts are dissolved before ' \
      'continuing with step 5. Avoid prolonged incubation, which may ' \
      'compromise RNA integrity.',
      'If desired, more than 30 mg tissue can be disrupted and homogenized ' \
      'at the start of the procedure (increase the volume of Buffer RLT ' \
      'proportionately). Use a portion of the homogenate corresponding to no ' \
      'more than 30 mg tissue for RNA purification, and store the rest at –80°C.',
      'Buffer RLT may form a precipitate upon storage. If necessary, ' \
      'redissolve by warming, and then place at room temperature (15–25°C).',
      'Buffer RLT and Buffer RW1 contain a guanidine salt and are therefore ' \
      'not compatible with disinfecting reagents containing bleach. See page ' \
      '6 for safety information.',
      'Perform all steps of the procedure at room temperature. During the ' \
      'procedure, work quickly.',
      'Perform all centrifugation steps at 20–25°C in a standard ' \
      'microcentrifuge. Ensure that the centrifuge does not cool below 20°C.'
    ]
    module_checklist_items.each_with_index do |item, ind|
      checklist.checklist_items << ChecklistItem.new(text: item, position: ind)
    end
    checklist.save

    # Add checklist 2 to step 1
    checklist = Checklist.new(
      name: 'Things to do before starting',
      step: step
    )
    module_checklist_items = [
      'β-Mercaptoethanol (β-ME) must be added to Buffer RLT before use. Add ' \
      '10 µl β-ME per 1 mL Buffer RLT. Dispense in a fume hood and wear ' \
      'appropriate protective clothing. Buffer RLT containing β-ME can be ' \
      'stored at room temperature (15–25°C) for up to 1 month. ' \
      'Alternatively, add 20 µL of 2 M dithiothreitol (DTT) per 1 mL Buffer ' \
      'RLT. The stock solution of 2 M DTT in water should be prepared fresh ' \
      'or frozen in single-use aliquots. Buffer RLT containing DTT can be ' \
      'stored at room temperature for up to 1 month.',
      'Buffer RPE is supplied as a concentrate. Before using for the first ' \
      'time, add 4 volumes of ethanol (96–100%) as indicated on the bottle ' \
      'to obtain a working solution.',
      'If performing optional on-column DNase digestion, prepare DNase I ' \
      'stock solution as described in Appendix D (page 67).'
    ]
    module_checklist_items.each_with_index do |item, ind|
      checklist.checklist_items << ChecklistItem.new(text: item, position: ind)
    end
    checklist.save

    # Add table to existig step 4
    step = my_modules[3].protocol.steps.where('position = 3').take
    Table.create(
      created_by: user,
      step: step,
      team: team,
      name: 'Volumes of Buffer RLT for tissue disruption and homogenization',
      contents: tab_content['module4']['volumes']
    )

    # Add checklist to step 8
    step = my_modules[3].protocol.steps.where('position = 7').take
    checklist = Checklist.new(
      name: 'Optional',
      step: step
    )
    module_checklist_items = [
      'If performing optional on-column DNase digestion (see “Eliminating ' \
      'genomic DNA contamination”, page 21), follow steps D1–D4 (page 67) ' \
      'after performing this step.'
    ]
    module_checklist_items.each_with_index do |item, ind|
      checklist.checklist_items << ChecklistItem.new(text: item, position: ind)
    end
    checklist.save

    # Results
    DelayedUploaderDemo.delay(queue: asset_queue).generate_result_asset(
      my_module: my_modules[3],
      current_user: user,
      current_team: team,
      result_name: 'Result of RNA integrity',
      created_at: generate_random_time(my_modules[3].created_at, 2.days),
      file_name: 'Bioanalyser_result.JPG'
    )
    temp_result = Result.new(
      name: 'DNA q results',
      my_module: my_modules[3],
      created_at: generate_random_time(my_modules[3].created_at, 1.days),
      user: user
    )
    temp_result.table = Table.new(
      created_by: user,
      team: team,
      contents: tab_content['module4']['dna_q']
    )
    temp_result.save

    # ----------------- Module 5 ------------------
    module_step_names = [
      'RNA denaturation',
      'Prepare mastermix for RT',
      'RT reaction'
    ]
    module_step_descriptions = [
      '1 ug of RNA denature at 80°C for 5 min --> ice',
      'High Capacity cDNA Reverse Transcription Kit (Applied Biosystems)',
      '25°C for 10 min 37°C for 2 h'
    ]
    generate_module_steps(my_modules[4],
                          module_step_names,
                          module_step_descriptions)

    module_checklist_items = [
      'H2O to 12.5 uL',
      'Optional: Luciferase mRNA (denatured)',
      'Reverse transcriptase',
      'RNase inhibitor',
      'Random Primers',
      'dNTP mix',
      'RT buffer'
    ]

    # Add checklist to step
    step = my_modules[4].protocol.steps.where('position = 1').take
    checklist = Checklist.new(
      name: 'Mastermix',
      step: step
    )

    module_checklist_items.each_with_index do |item, ind|
      checklist.checklist_items << ChecklistItem.new(text: item, position: ind)
    end
    checklist.save

    # ----------------- Module 6 ------------------
    module_step_names = [
      'Master Mix Preparation',
      'Setup of the 96-well Plate',
      'Reaction setup - NEW TITLE'
    ]
    module_step_descriptions = [
      'PCR Master Mix includes Nuclease-Free Water and PCR Master Mix, 2X. ' \
      'PCR Master Mix is a premixed, ready-to-use solution containing Taq ' \
      'DNA Polymerase, dNTPs, MgCl2 and reaction buffers at optimal ' \
      'concentrations for efficient amplification of DNA templates by PCR.',
      '<html><body><p>It is recommended to use pre-defined Excel templates ' \
      'or PlatR Pietting Assistant to customize pipetting scheme. Make sure ' \
      'to always include all necessary controls.&nbsp;Especially the ' \
      'negative controls.<br><br>Template of the 96-well plate.' \
      '</p></body></html>',
      '<html><body><p>The Applied Biosystems 7900HT Fast Real-Time PCR ' \
      'System (7900HT Fast System) uses fluorescent-based PCR chemistries to ' \
      'provide:</p><ul><li>Quantitative detection of nucleic acid sequences ' \
      'using real-time analysis</li><li>Qualitative detection of nucleic ' \
      'acid sequences using end-point and dissociation-curve analysis</li>' \
      '</ul><p>You can perform several assay types on the 7900HT Fast System ' \
      'using reactions plates in the 96-well, 384-well, or TaqMan® Low ' \
      'Density Array format. This guide describes the allelic discrimination ' \
      'assay.</p></body></html>'
    ]
    generate_module_steps(my_modules[5],
                          module_step_names,
                          module_step_descriptions)

    # Add table to existig step 1
    step = my_modules[5].protocol.steps.where('position = 0').take
    Table.create(
      created_by: user,
      step: step,
      team: team,
      name: 'Realtime mastermix preparation - gene expression',
      contents: tab_content['module6']['mastermix']
    )

    # Add checklist to step 1
    step = my_modules[5].protocol.steps.where('position = 0').take
    checklist = Checklist.new(
      name: 'QA checklist',
      step: step
    )
    module_checklist_items = [
      'Make sure the UV light was on at least for 20 minutes before you ' \
      'started to work',
      'Write down LOT numbers of reagents used',
      'Use tips with filtes for pipetting samples; use tips without filters ' \
      'for pipetting reagents',
      'Always use designated separate chambers for pipetting samples and ' \
      'reagents',
      'Change lab coats when switching chambers',
      'Clean surfaces with 70% ethanol or RNA remover',
      'Turn on the UV light'
    ]
    module_checklist_items.each_with_index do |item, ind|
      checklist.checklist_items << ChecklistItem.new(text: item, position: ind)
    end
    checklist.save

    # Add file to existig steps
    DelayedUploaderDemo.delay(queue: asset_queue).add_step_asset(
      step: my_modules[5].protocol.steps.where('position = 0').take,
      current_user: user,
      current_team: team,
      file_name: 'Mixes_Templats.xlsx'
    )

    DelayedUploaderDemo.delay(queue: asset_queue).add_step_asset(
      step: my_modules[5].protocol.steps.where('position = 1').take,
      current_user: user,
      current_team: team,
      file_name: 'qPCR_template.jpg'
    )

    DelayedUploaderDemo.delay(queue: asset_queue).add_step_asset(
      step: my_modules[5].protocol.steps.where('position = 1').take,
      current_user: user,
      current_team: team,
      file_name: '96plate.docx'
    )

    DelayedUploaderDemo.delay(queue: asset_queue).add_step_asset(
      step: my_modules[5].protocol.steps.where('position = 2').take,
      current_user: user,
      current_team: team,
      file_name: 'cycling_conditions.JPG'
    )

    DelayedUploaderDemo.delay(queue: asset_queue).add_step_asset(
      step: my_modules[5].protocol.steps.where('position = 2').take,
      current_user: user,
      current_team: team,
      file_name: 'Dual_Labeled_Fluorescent_Probes.jpg'
    )

    # Results
    # Add a hard-coded table result
    temp_result = Result.new(
      name: 'Sample distribution on the plate',
      my_module: my_modules[5],
      user: user,
      created_at: generate_random_time(my_modules[5].created_at, 1.days)
    )
    temp_result.table = Table.new(
      created_by: user,
      team: team,
      contents: tab_content['module6']['distribution'] % {
        sample0: samples_to_assign[0].name,
        sample1: samples_to_assign[1].name,
        sample2: samples_to_assign[2].name,
        sample3: samples_to_assign[3].name
      }
    )
    temp_result.save

    # Results
    DelayedUploaderDemo.delay(queue: asset_queue).generate_result_asset(
      my_module: my_modules[5],
      current_user: user,
      current_team: team,
      result_name: 'Results',
      created_at: generate_random_time(my_modules[5].created_at, 2.days),
      file_name: '1505745387970-1058053257.jpg'
    )

    DelayedUploaderDemo.delay(queue: asset_queue).generate_result_asset(
      my_module: my_modules[5],
      current_user: user,
      current_team: team,
      result_name: 'Cromatogram',
      created_at: generate_random_time(my_modules[5].created_at, 3.days),
      file_name: 'chromatogram.png'
    )

    DelayedUploaderDemo.delay(queue: asset_queue).generate_result_asset(
      my_module: my_modules[5],
      current_user: user,
      current_team: team,
      result_name: 'All results - curves',
      created_at: generate_random_time(my_modules[5].created_at, 4.days),
      file_name: 'curves.JPG'
    )

    DelayedUploaderDemo.delay(queue: asset_queue).generate_result_asset(
      my_module: my_modules[5],
      current_user: user,
      current_team: team,
      result_name: 'Bacteria plates YPGA',
      created_at: generate_random_time(my_modules[5].created_at, 2.days),
      file_name: 'Bacterial_colonies.jpg',
      comment: user_annotation + ' please check the results again. ' \
          '<span class=\"atwho-inserted\" contenteditable=\"false\"' \
          'data-atwho-at-query=\"#\">[#' + fifth_rep_item + ']</span>' \
          ' seems to be acting strange?'
    )

    DelayedUploaderDemo.delay(queue: asset_queue).generate_result_asset(
      my_module: my_modules[5],
      current_user: user,
      current_team: team,
      result_name: 'Article',
      created_at: generate_random_time(my_modules[5].created_at, 4.days),
      file_name: 'Recent_attempts_to_detect_Ebola_virus.docx'
    )

    # Add a text result
    temp_result = Result.new(
      name: 'Data analysis',
      my_module: my_modules[5],
      user: user,
      created_at: generate_random_time(my_modules[5].created_at, 4.days)
    )

    temp_result.result_text = ResultText.new(
      text: <<~FOO
        <html><body><pre class='hljs  language-python'>
        <code># Read PCR data into a pandas DataFrame. You want a data file where each
        # row corresponds to a separate well, with columns for the sample name,
        # target name, and Cq value. NTC wells should have the sample name set to
        # a value like 'NTC'.
        &gt;&gt; df = pd.read_csv('my_data.csv')

        # If your Sample, Target, and Cq columns are called other things, they
        # should be renamed to Sample, Target, and Cq.
        &gt;&gt; df = df.rename(columns={'Gene': 'Target', 'Ct': 'Cq'})

        # Drop the wells that are too close to the NTC for that target.
        &gt;&gt; censored = eleven.censor_background(df)

        # Rank your candidate reference genes.
        &gt;&gt; ranked = eleven.rank_targets(censored, ['Gapdh', 'Rn18s', 'Hprt',
            'Ubc', 'Actb'], 'Control')

        # Normalize your data by your most stable genes and compute normalization
        # factors (NFs).
        &gt;&gt; nf = eleven.calculate_nf(censored, ranked.ix['Target', 0:3], 'Control')

        # Now, normalize all of your expression data.
        &gt;&gt; censored['RelExp'] = eleven.expression_nf(censored, nf, 'Control')</code>
        </pre></body></html>
      FOO
    )
    temp_result.save

    # Add a text result
    temp_result = Result.new(
      name: 'Immunofluorescence summary',
      my_module: my_modules[5],
      user: user,
      created_at: generate_random_time(my_modules[5].created_at, 4.days)
    )

    temp_result.result_text = ResultText.new(
      text: 'Immunofluorescence is a technique used for light microscopy ' \
      'with a fluorescence microscope and is used primarily on ' \
      'microbiological samples. This technique uses the specificity of ' \
      'antibodies to their antigen to target fluorescent dyes to specific ' \
      'biomolecule targets within a cell, and therefore allows visualization ' \
      'of the distribution of the target molecule through the sample. The ' \
      'specific region an antibody recognizes on an antigen is called an ' \
      'epitope. There have been.'
    )
    temp_result.save

    # Add a text result
    temp_result = Result.new(
      name: 'Discussion',
      my_module: my_modules[5],
      user: user,
      created_at: generate_random_time(my_modules[5].created_at, 4.days)
    )

    temp_result.result_text = ResultText.new(
      text: 'Immunofluorescence is a technique used for light microscopy ' \
      'with a fluorescence microscope and is used primarily on ' \
      'microbiological samples. this technique uses the specificity of ' \
      'antibodies to their antigen to target fluorescent dyes to specific ' \
      'biomolecule targets within a cell, and therefore allows visualization ' \
      'of the distribution of the target molecule through the sample. the ' \
      'specific region an antibody recognizes on an antigen is called an ' \
      'epitope. There have been efforts in epitope mapping since many ' \
      'antibodies can bind the same epitope and levels of binding between ' \
      'antibodies that recognize the same epitope can vary. Additionally, ' \
      'the binding of the fluorophore to the antibody itself cannot ' \
      'interfere with the immunological specificity of the antibody or the ' \
      'binding capacity of its antigen. Immunofluorescence is a widely used ' \
      'example of immunostaining (using antibodies to stain proteins) and ' \
      'is a specific example of immunohistochemistry(the use of the ' \
      'antibody-antigen relationship in tissues). this technique primarily ' \
      'makes use of fluorophores to visualise the location of the antibodies.'
    )
    temp_result.save

    # Add table result
    temp_result = Result.new(
      name: 'qPCR raw data',
      my_module: my_modules[5],
      user: user,
      created_at: generate_random_time(my_modules[5].created_at, 1.days)
    )
    temp_result.table = Table.new(
      created_by: user,
      team: team,
      contents: tab_content['module6']['qpcr_raw_data']
    )
    temp_result.save

    # ----------------- Module 7 ------------------
    module_step_names = [
      'Native PAGE protocol',
      'QA Checklist',
      'Check negative controls NTC',
      'Eliminate results that have positive NTCs',
      'Native-Page Protocol',
      'Excel results'
    ]
    module_step_descriptions = [
      'Protein electrophoresis is a method for analysing the proteins in a ' \
      'fluid or an extract. The electrophoresis may be performed with a ' \
      'small volume of sample in a number of alternative ways with or ' \
      'without a supporting medium: SDS polyacrylamide gel electrophoresis ' \
      '(in short: gel electrophoresis, PAGE, or SDS-electrophoresis), ' \
      'free-flow electrophoresis, electrofocusing, isotachophoresis, ' \
      'affinity electrophoresis, immunoelectrophoresis, ' \
      'counterelectrophoresis, and capillary electrophoresis. Each method ' \
      'has many variations with individual advantages and limitations. Gel ' \
      'electrophoresis is often performed in combination with ' \
      'electroblotting immunoblotting to give additional information about a ' \
      'specific protein. Because of practical limitations, protein ' \
      'electrophoresis is generally not suited as a preparative method.',
      'Please perform the following checklist before and after you start ' \
      'working.',
      '<html><body><div class="row">They have to be negative when using ' \
      'TaqMan assays.<br><ul><li class="col-xs-12">If they are positive when ' \
      'using SYBR assays check also melitng curve where signal comes ' \
      'from</li><li class="col-xs-12">If it is primer dimer result is ' \
      'negative</li><li class="col-xs-12">If it is specific signal it is ' \
      'positive.</li></ul></div></body></html>',
      'And repeat procedure.',
      'Follow a Nature protocol attached and a PDF.',
      'Write results in excel file.'
    ]
    generate_module_steps(my_modules[6],
                          module_step_names,
                          module_step_descriptions)

    # Add file to existig steps
    DelayedUploaderDemo.delay(queue: asset_queue).add_step_asset(
      step: my_modules[6].protocol.steps.where('position = 0').take,
      current_user: user,
      current_team: team,
      file_name: 'Native_SDS-PAGE_for_complex_analysis.jpg'
    )

    DelayedUploaderDemo.delay(queue: asset_queue).add_step_asset(
      step: my_modules[6].protocol.steps.where('position = 4').take,
      current_user: user,
      current_team: team,
      file_name: 'Native-PAGE-Nature_protocols.pdf'
    )

    DelayedUploaderDemo.delay(queue: asset_queue).add_step_asset(
      step: my_modules[6].protocol.steps.where('position = 5').take,
      current_user: user,
      current_team: team,
      file_name: 'results.xlsx'
    )

    # Add checklist to step 2
    step = my_modules[6].protocol.steps.where('position = 1').take
    checklist = Checklist.new(
      name: 'QA Native PAGE',
      step: step
    )
    module_checklist_items = [
      'Check buffer stock & prepare new stock if needed',
      'Check stock of reagents & order new stock if needed',
      'Use gloves at all times'
    ]
    module_checklist_items.each_with_index do |item, ind|
      checklist.checklist_items << ChecklistItem.new(text: item, position: ind)
    end
    checklist.save

    # Results
    # Add table result
    temp_result = Result.new(
      name: 'qPCR results',
      my_module: my_modules[6],
      user: user,
      created_at: generate_random_time(my_modules[6].created_at, 1.days)
    )
    temp_result.table = Table.new(
      created_by: user,
      team: team,
      contents: tab_content['module7']['qpcr_results']
    )
    temp_result.save

    # ----------------- Module 8 ------------------
    module_step_names = [
      'Template for ddCq analysis'
    ]
    module_step_descriptions = [
      'Sample information here.'
    ]

    generate_module_steps(my_modules[7],
                          module_step_names,
                          module_step_descriptions)

    # Add file to existig step
    DelayedUploaderDemo.delay(queue: asset_queue).add_step_asset(
      step: my_modules[7].protocol.steps.where('position = 0').take,
      current_user: user,
      current_team: team,
      file_name: 'ddCq-quantification_diagnostics-template.xls'
    )

    DelayedUploaderDemo.delay(queue: asset_queue).add_step_asset(
      step: my_modules[7].protocol.steps.where('position = 0').take,
      current_user: user,
      current_team: team,
      file_name: 'SDHACOX1Beta-Actin-Kits-ab123545-1.gif'
    )

    # Add comment to step 3
    step = my_modules[7].protocol.steps.where('position = 0').take
    generate_step_comment(
      step,
      user,
      'I actually ran it for 15 minutes and not 10.'
    )

    # Add result
    DelayedUploaderDemo.delay(queue: asset_queue).generate_result_asset(
      my_module: my_modules[7],
      current_user: user,
      current_team: team,
      result_name: 'Template for ddCq analysis',
      created_at: generate_random_time(my_modules[7].created_at, 1.days),
      file_name: 'ddCq-quantification_diagnostics-results.xls'
    )

    DelayedUploaderDemo.delay(queue: asset_queue).generate_result_asset(
      my_module: my_modules[7],
      current_user: user,
      current_team: team,
      result_name: 'Dilution curve and efficiency',
      created_at: generate_random_time(my_modules[7].created_at, 2.days),
      file_name: 'dilution_curve-efficiency.JPG'
    )

    DelayedUploaderDemo.delay(queue: asset_queue).generate_result_asset(
      my_module: my_modules[7],
      current_user: user,
      current_team: team,
      result_name: 'Relative quantification results',
      created_at: generate_random_time(my_modules[7].created_at, 3.days),
      file_name: 'result-ddCq.JPG'
    )

    # create thumbnail
    experiment.generate_workflow_img
  end

  # Used for delayed jobs
  def self.seed_demo_data_with_id(user_id, team_id)
    extend self
    user = User.find(user_id)
    team = Team.find(team_id)

    unless user || team
      Rails.logger.warning("Could not retrieve user or team in " \
                           "seed_demo_data_with_id. " \
                           "User #{user_id} was mapped to #{user.inspect}." \
                           "Team #{team_id} was mapped to #{team.inspect}.")
      return
    end

    seed_demo_data(user, team, :new_demo_project)
  end

  # WARNING: This only works on PostgreSQL
  def pluck_random(scope)
    scope.order('RANDOM()').first
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
      completed_on = nil
      completed_on = generate_random_time(created_at, 10.hours) if completed

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

      if completed
        # Also add random comments to completed steps
        if rand < 0.3
          polite_comment = 'This looks well.'
        elsif rand < 0.4
          polite_comment = 'Great job!'
        elsif rand < 0.4
          polite_comment = 'Thanks for getting this done.'
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
    ProjectComment.create(
      user: user,
      message: message,
      created_at: created_at,
      project: project
    )
  end

  def generate_module_comment(my_module, user, message, created_at = nil)
    created_at ||= generate_random_time(my_module.created_at, 1.day)
    TaskComment.create(
      user: user,
      message: message,
      created_at: created_at,
      my_module: my_module
    )
  end


  def generate_result_comment(result, user, message, created_at = nil)
    created_at ||= generate_random_time(result.created_at, 1.days)
    ResultComment.create(
      user: user,
      message: message,
      created_at: created_at,
      result: result
    )
  end

  def generate_step_comment(step, user, message, created_at = nil)
    created_at ||= generate_random_time(step.created_at, 2.hours)
    StepComment.create(
      user: user,
      message: message,
      created_at: created_at,
      step: step
    )
  end

  def smart_annotate_rep_item(item)
    "#{item.name}~rep_item~#{Base62.encode(item.id)}"
  end
end
