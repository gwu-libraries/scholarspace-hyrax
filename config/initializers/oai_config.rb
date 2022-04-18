OAI_CONFIG =
    {
        provider: {
            repository_name: 'GW ScholarSpace',
            #repository_url: 'http://localhost/catalog/oai',     # todo: can we get this from the other places that use the base url?
            #repository_url: 'https://ec2-3-137-137-212.us-east-2.compute.amazonaws.com',
            record_prefix: 'oai:scholarspace.library.gwu.edu',
            admin_email: 'schol_comm@gwu.edu',
            sample_id: 'z316q1572'
        },
        document: {
            limit: 25,            # number of records returned with each request, default: 15
            #supported_formats: ['oai_dc'],
            set_fields: [
            { label: 'type', solr_field: 'human_readable_type_tesim' }
          ]

        },
        record_filters: [
          # limit access to public records
          #'read_access_group_ssim: "public"',
          # Get only those records in deposited workflow state
          #'workflow_state_name_ssim: "deposited"'
        ]
    }