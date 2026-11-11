import Component from "@glimmer/component";
import { service } from "@ember/service";
import { tracked } from "@glimmer/tracking";
import { modifier } from "ember-modifier";
import coldAgeClass from "discourse/helpers/cold-age-class";
import concatClass from "discourse/helpers/concat-class";
import dIcon from "discourse/helpers/d-icon";
import formatDate from "discourse/helpers/format-date";

const HeartIcon = <template>
  <svg
    class="topic-thumbnail-heart"
    viewBox="0 0 1024 1024"
    width="18"
    height="18"
    aria-hidden="true"
  >
    <path
      d="M695.30624 143.44192c-41.85088 7.28576-76.5184 20.25472-105.76384 40.01792l-30.00832 24.2944-47.16544 47.16544C445.07648 203.27936 416.09728 139.9808 290.83648 142.00832l-52.87936 8.576c-45.00992 13.68064-88.192 39.87456-114.33984 72.89344-15.35488 19.38944-30.36672 42.7008-40.01792 67.1744-56.9856 144.5376 41.74848 234.69056 108.6208 301.568l117.1968 115.7632 144.35328 142.9248c17.43872 14.08512 30.55616 38.17984 68.60288 31.44704 45.5424-8.064 93.2608-74.69056 122.91072-104.33536a2629899.9808 2629899.9808 0 0 1 170.07616-168.64768c52.47488-52.46976 111.60064-96.25088 134.3488-178.65216 43.14112-156.30336-101.55008-313.90208-254.40256-287.27808z m184.36608 314.42432c-22.13888 37.94432-57.02656 65.60256-87.17312 95.75936-56.68864 56.2176-113.38752 112.44032-170.08128 168.64768-15.55968 15.55456-95.83104 104.43776-110.04928 102.90688-14.14656 1.25952-33.00352-27.35616-42.88-37.16096l-114.33472-112.91136c-46.68928-46.19776-93.38368-92.42624-140.0576-138.63424-27.06944-27.06432-59.50976-52.54144-75.76064-90.0352-28.83072-66.52928-7.79264-149.32992 30.01856-190.09024 21.36576-23.04 51.52256-43.21792 85.75488-52.87936 12.38016-1.90464 24.76544-3.8144 37.15584-5.71392 71.44448 0.31232 87.64928 26.24512 131.48672 47.16032l88.61184 88.61184c45.78816-35.10784 76.7488-89.99424 130.05824-117.1968 116.6592-59.52 231.63392 24.5248 254.40256 121.48736 9.91232 42.18368-1.33632 92.96384-17.152 120.04864z"
      fill="#A5A7AC"
    />
  </svg>
</template>;

const CommentIcon = <template>
  <svg
    class="topic-thumbnail-comment"
    viewBox="0 0 1024 1024"
    width="18"
    height="18"
    aria-hidden="true"
  >
    <path
      d="M379.733333 913.066667h-8.533333c-21.333333-4.266667-38.4-17.066667-46.933333-34.133334l-29.866667-72.533333H226.133333c-76.8 0-140.8-64-140.8-140.8V251.733333C85.333333 170.666667 149.333333 110.933333 226.133333 110.933333h571.733334C874.666667 110.933333 938.666667 170.666667 938.666667 251.733333v413.866667c0 76.8-64 140.8-140.8 140.8h-307.2l-64 85.333333c-8.533333 12.8-25.6 21.333333-46.933334 21.333334zM226.133333 174.933333c-42.666667 0-76.8 34.133333-76.8 76.8v413.866667c0 42.666667 34.133333 76.8 76.8 76.8h110.933334l42.666666 102.4 76.8-102.4h337.066667c42.666667 0 76.8-34.133333 76.8-76.8V251.733333c0-42.666667-34.133333-76.8-76.8-76.8H226.133333z"
      fill="#A5A7AC"
    />
    <path
      d="M285.866667 469.333333m-51.2 0a51.2 51.2 0 1 0 102.4 0 51.2 51.2 0 1 0-102.4 0Z"
      fill="#A5A7AC"
    />
    <path
      d="M512 469.333333m-51.2 0a51.2 51.2 0 1 0 102.4 0 51.2 51.2 0 1 0-102.4 0Z"
      fill="#A5A7AC"
    />
    <path
      d="M738.133333 469.333333m-51.2 0a51.2 51.2 0 1 0 102.4 0 51.2 51.2 0 1 0-102.4 0Z"
      fill="#A5A7AC"
    />
  </svg>
</template>;

export default class TopicListThumbnail extends Component {
  @service topicThumbnails;
  @service("topic-content-loader") contentLoader;

  @tracked extractedImages = [];
  @tracked isLoading = false;
  @tracked hasLoaded = false;

  responsiveRatios = [1, 1.5, 2];

  // Make sure to update about.json thumbnail sizes if you change these variables
  get displayWidth() {
    return this.topicThumbnails.displayList
      ? settings.list_thumbnail_size
      : 400;
  }

  get topic() {
    return this.args.topic;
  }

  // Intersection Observer 用于检测元素是否进入视口
  intersectionObserver = null;

  get hasThumbnail() {
    if (this.topicThumbnails.displayBlogStyle) {
      // blog-style 模式：检查是否有提取的图片
      return this.imageUrls.length > 0;
    }
    // 其他模式：使用原有逻辑
    return !!this.topic.thumbnails;
  }

  async loadImages() {
    // 防止重复加载
    if (this.isLoading || this.hasLoaded) {
      return;
    }

    // blog-style 模式：从详情中加载图片
    if (this.topicThumbnails.displayBlogStyle) {
      const topicId = this.topic.id || this.topic.get?.("id");
      if (topicId) {
        this.isLoading = true;
        try {
          const images = await this.contentLoader.loadTopicImages(topicId);
          this.extractedImages = images;
          this.hasLoaded = true;
        } catch (error) {
          console.error(`Failed to load images for topic ${topicId}:`, error);
        } finally {
          this.isLoading = false;
        }
      }
    }
  }

  // 使用 Intersection Observer 检测元素是否进入视口
  setupIntersectionObserver = modifier((element) => {
    // 只在 blog-style 模式下使用懒加载
    if (!this.topicThumbnails.displayBlogStyle) {
      return;
    }

    // 如果已经加载过，直接返回
    if (this.hasLoaded) {
      return;
    }

    // 检查浏览器是否支持 Intersection Observer
    if (!window.IntersectionObserver) {
      // 如果不支持，直接加载
      this.loadImages();
      return;
    }

    // 创建 Intersection Observer
    this.intersectionObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          // 当元素进入视口时（至少 10% 可见），开始加载
          if (entry.isIntersecting && entry.intersectionRatio >= 0.1) {
            this.loadImages();
            // 加载后停止观察
            if (this.intersectionObserver) {
              this.intersectionObserver.unobserve(element);
            }
          }
        });
      },
      {
        // 当元素 10% 进入视口时触发
        threshold: 0.1,
        // 提前 100px 开始加载（预加载）
        rootMargin: "100px",
      }
    );

    // 开始观察元素
    this.intersectionObserver.observe(element);

    // 清理函数
    return () => {
      if (this.intersectionObserver) {
        this.intersectionObserver.disconnect();
        this.intersectionObserver = null;
      }
    };
  });

  get imageUrls() {

    if (this.topicThumbnails.displayBlogStyle) {
      // blog-style 模式：使用从详情中提取的图片
      return this.extractedImages;
    }
    
    // 其他模式：使用系统返回的缩略图
    if (this.topic.thumbnails && this.topic.thumbnails.length > 0) {
      return [this.topic.thumbnails[0].url];
    }

    return [];
  }

  get srcSet() {
    const srcSetArray = [];

    this.responsiveRatios.forEach((ratio) => {
      const target = ratio * this.displayWidth;
      const match = this.topic.thumbnails.find(
        (t) => t.url && t.max_width === target
      );
      if (match) {
        srcSetArray.push(`${match.url} ${ratio}x`);
      }
    });

    if (srcSetArray.length === 0) {
      srcSetArray.push(`${this.original.url} 1x`);
    }

    return srcSetArray.join(",");
  }

  get original() {
    return this.topic.thumbnails[0];
  }

  get width() {
    return this.original.width;
  }

  get isLandscape() {
    return this.original.width >= this.original.height;
  }

  get height() {
    return this.original.height;
  }

  get fallbackSrc() {
    const largeEnough = this.topic.thumbnails.filter((t) => {
      if (!t.url) {
        return false;
      }
      return t.max_width > this.displayWidth * this.responsiveRatios.lastObject;
    });

    if (largeEnough.lastObject) {
      return largeEnough.lastObject.url;
    }

    return this.original.url;
  }

  get url() {
    return this.topic.get("linked_post_number")
      ? this.topic.urlForPostNumber(this.topic.get("linked_post_number"))
      : this.topic.get("lastUnreadUrl");
  }

  get createdBy() {
    // posters 数组中的第一个通常是创建者
    if (this.topic.posters && this.topic.posters.length > 0) {
      return this.topic.posters[0];
    }

    return null;
  }

  get avatarUrl() {
    if (!this.createdBy) return null;
    let avatarTemplate = this.createdBy.user.avatar_template 
    
    if (!avatarTemplate) return null;
    
    // Discourse avatar template format: {size}/{version}.png
    // 需要替换 {size} 为实际大小
    if (avatarTemplate.includes("{size}")) {
      return avatarTemplate.replace("{size}", "40");
    }
    return avatarTemplate;
  }

  get posts_count() {
    return this.topic.posts_count - 1;
  }

  get username() {
    return this.topic.posters[0].user.username
  }

  get userUrl() {
    // 获取用户详情页 URL
    const username = this.username;
    if (username) {
      return `/u/${username}`;
    }
    return "#";
  }

  get createdAt() {
    // 尝试多种方式获取创建时间
    return (
      this.topic.created_at || (this.topic.get && this.topic.get("created_at"))
    );
  }

  <template>
    {{#if this.topicThumbnails.displayBlogStyle}}
      {{! Blog style 布局：顶部用户信息 + 底部图片 + 右下角互动指标 }}
      {{! 顶部：用户信息 }}
      {{! 使用 modifier 设置 Intersection Observer，监听 header 元素（第一个可见元素）}}
      <div {{this.setupIntersectionObserver}} class="topic-thumbnail-blog-header">
        <div class="topic-thumbnail-blog-user-info">
          <a href={{this.userUrl}} class="topic-thumbnail-blog-avatar-link">
            <div class="topic-thumbnail-blog-avatar">
            {{#if this.avatarUrl}}
                <img src={{this.avatarUrl}} alt={{this.username}} />
            {{else}}
                {{dIcon "user"}}
            {{/if}}
            </div>
          </a>
          <div class="topic-thumbnail-blog-user-details">
            <a href={{this.userUrl}} class="topic-thumbnail-blog-username-link">
              <div class="topic-thumbnail-blog-username">
                  {{this.username}}
              </div>
            </a>
            {{#if this.createdAt}}
              <div class="topic-thumbnail-blog-date">
                {{~formatDate this.createdAt format="medium" noTitle="true"~}}
              </div>
            {{/if}}
          </div>
        </div>
      </div>
 
      {{! 底部：图片区域 }}
      {{#if this.hasThumbnail}}
        <div class="topic-thumbnail-blog-images">
          {{#each this.imageUrls as |imageUrl|}}
            <div class="topic-list-thumbnail has-thumbnail">
              <a href={{this.url}} role="img" aria-label={{this.topic.title}}>
                <img
                  class="main-thumbnail"
                  src={{imageUrl}}
                  loading="lazy"
                  alt=""
                />
              </a>
            </div>
          {{/each}}
        </div>
      {{/if}}

      {{! 右下角：互动指标（点赞和评论）}}
      <div class="topic-thumbnail-blog-engagement">
        <div class="topic-thumbnail-blog-engagement-item">
          <CommentIcon />
          <span class="number">
            {{this.posts_count}}
          </span>
        </div>
        <div class="topic-thumbnail-blog-engagement-item">
          <HeartIcon />
          <span class="number">
            {{this.topic.like_count}}
          </span>
        </div>
      </div>
    {{else}}
      {{! 其他布局模式：保持原有结构 }}
      <div
        class={{concatClass
          "topic-list-thumbnail"
          (if this.hasThumbnail "has-thumbnail" "no-thumbnail")
        }}
      >
        <a href={{this.url}} role="img" aria-label={{this.topic.title}}>
          {{#if this.hasThumbnail}}
            <img
              class="background-thumbnail"
              src={{this.fallbackSrc}}
              srcset={{this.srcSet}}
              width={{this.width}}
              height={{this.height}}
              loading="lazy"
              alt=""
            />
            <img
              class="main-thumbnail"
              src={{this.fallbackSrc}}
              srcset={{this.srcSet}}
              width={{this.width}}
              height={{this.height}}
              loading="lazy"
              alt=""
            />
          {{else}}
            <div class="thumbnail-placeholder">
              {{dIcon settings.placeholder_icon}}
            </div>
          {{/if}}
        </a>
      </div>

      {{#if this.topicThumbnails.showLikes}}
        <div class="topic-thumbnail-likes">
          <HeartIcon />
          <span class="number">
            {{this.topic.like_count}}
          </span>
        </div>
      {{/if}}
    {{/if}}
  </template>
}
