<template>
  <div class="relative w-6 h-6" :title="title">
      <img v-if="avatarUrl" src="avatarUrl" class="rounded-full w-full h-full" />
      <div v-else class="w-full h-full rounded-full border border-sn-light-grey  bg-sn-super-light-grey flex justify-center items-center">
        <span class="text-[.625rem] leading-3 font-normal">
          {{ initials }}
        </span>
      </div>
  </div>
</template>

<script>
export default {
  name: 'UserAvatar',
  props: {
    title: String,
    initials: String,
    avatarUrl: String
  }
}
</script>
