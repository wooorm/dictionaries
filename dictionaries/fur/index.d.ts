interface Doc {
    aff: Buffer,
    dic: Buffer
}

export default function (callback: (err?: Error, doc?: Doc) => void ): void;
