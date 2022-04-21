<template>
    <div class="task-protocol">
      <div class="task-section-header">
        <a class="task-section-caret" role="button" data-toggle="collapse" href="#protocol-content" aria-expanded="true" aria-controls="protocol-content">
          <i class="fas fa-caret-right"></i>
          <div class="task-section-title">
            <h2>{{ i18n.t('Protocol') }}</h2>
          </div>
        </a>
      </div>
      <div id="protocol-content" class="protocol-content collapse in" aria-expanded="true">
        <div class="protocol-description">
          <input type="text" class="inline" :model="protocol.name" :placeholder="i18n.t('my_modules.protocols.protocol_status_bar.enter_name')">
        </div>
        <div class="protocol-steps">
          Steps go here
        </div>
      </div>
    </div>
</template>

 <script>
  export default {
    name: 'ProtocolContainer',
    props: {
      protocolUrl: String, required: true
    },
    data() {
      return {
        protocol: {}
      }
    },
    created() {
      $.get(this.protocolUrl, (data) => {
        this.protocol = data;
      });
    },
    methods: {}
  }
 </script>
