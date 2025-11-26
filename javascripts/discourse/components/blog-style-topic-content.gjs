import Component from "@glimmer/component";
import { service } from "@ember/service";
import formatDate from "discourse/helpers/format-date";

export default class BlogStyleTopicContent extends Component {
  @service topicThumbnails;

  get topic() {
    return this.args.topic;
  }

  get title() {
    return this.topic.title || this.topic.fancy_title || "";
  }

  get excerpt() {
    return this.topic.excerpt || this.topic.blurb || "";
  }

  get url() {
    return this.topic.get("linked_post_number")
      ? this.topic.urlForPostNumber(this.topic.get("linked_post_number"))
      : this.topic.get("lastUnreadUrl");
  }

  <template>
    {{! 自定义标题和内容区域 }}
    <div class="blog-style-topic-content">
      <div class="blog-style-topic-title">
        <a href={{this.url}} class="blog-style-title-link">
          {{this.title}}
        </a>
      </div>
      {{#if this.excerpt}}
        <div class="blog-style-topic-excerpt">
          {{this.excerpt}}
        </div>
      {{/if}}
    </div>
  </template>
}

